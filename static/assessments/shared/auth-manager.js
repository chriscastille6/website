// Authentication Manager
// Location: /static/assessments/shared/auth-manager.js
// Purpose: User authentication and session management for assessment library
// Why: Provides secure user login, registration, and session management
// RELEVANT FILES: static/assessments/shared/supabase-client.js, static/assessments/auth/login.html

// Authentication manager class
class AuthManager {
    constructor() {
        this.supabase = window.AssessmentLibrary?.supabase || window.supabase.createClient(
            window.AssessmentLibrary?.SUPABASE_CONFIG?.url || 'YOUR_SUPABASE_URL',
            window.AssessmentLibrary?.SUPABASE_CONFIG?.anonKey || 'YOUR_SUPABASE_ANON_KEY',
            {
                auth: {
                    persistSession: true,
                    autoRefreshToken: true
                }
            }
        );
        this.currentUser = null;
        this.userProfile = null;
    }

    /**
     * Get current authenticated user
     */
    async getCurrentUser() {
        const { data: { user }, error } = await this.supabase.auth.getUser();
        if (error) {
            console.error('Error getting current user:', error);
            return null;
        }
        this.currentUser = user;
        return user;
    }

    /**
     * Get user profile from users table
     */
    async getUserProfile() {
        const user = await this.getCurrentUser();
        if (!user) return null;

        const { data, error } = await this.supabase
            .from('users')
            .select('*')
            .eq('id', user.id)
            .single();

        if (error) {
            console.error('Error getting user profile:', error);
            return null;
        }

        this.userProfile = data;
        return data;
    }

    /**
     * Sign up new user
     */
    async signUp(email, password, fullName, labId = null) {
        try {
            // Sign up with Supabase Auth
            const { data: authData, error: authError } = await this.supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        full_name: fullName
                    }
                }
            });

            if (authError) throw authError;

            // Create user record in users table
            if (authData.user) {
                // Get default PAL lab if no lab specified
                if (!labId) {
                    const { data: palLab } = await this.supabase
                        .from('labs')
                        .select('id')
                        .eq('name', 'PAL')
                        .single();

                    if (palLab) labId = palLab.id;
                }

                const { error: userError } = await this.supabase
                    .from('users')
                    .insert([{
                        id: authData.user.id,
                        email: email,
                        full_name: fullName,
                        lab_id: labId,
                        role: 'participant'
                    }]);

                if (userError) {
                    console.error('Error creating user record:', userError);
                    // User created in auth but not in users table - will be created on first login
                }
            }

            return { user: authData.user, error: null };
        } catch (error) {
            console.error('Sign up error:', error);
            return { user: null, error };
        }
    }

    /**
     * Sign in existing user
     */
    async signIn(email, password) {
        try {
            const { data, error } = await this.supabase.auth.signInWithPassword({
                email,
                password
            });

            if (error) throw error;

            // Ensure user record exists in users table
            if (data.user) {
                const { data: userRecord } = await this.supabase
                    .from('users')
                    .select('id')
                    .eq('id', data.user.id)
                    .single();

                if (!userRecord) {
                    // Create user record if it doesn't exist
                    const { data: palLab } = await this.supabase
                        .from('labs')
                        .select('id')
                        .eq('name', 'PAL')
                        .single();

                    await this.supabase
                        .from('users')
                        .insert([{
                            id: data.user.id,
                            email: email,
                            full_name: data.user.user_metadata?.full_name || null,
                            lab_id: palLab?.id || null,
                            role: 'participant'
                        }]);
                }
            }

            this.currentUser = data.user;
            return { user: data.user, error: null };
        } catch (error) {
            console.error('Sign in error:', error);
            return { user: null, error };
        }
    }

    /**
     * Sign out current user
     */
    async signOut() {
        try {
            const { error } = await this.supabase.auth.signOut();
            if (error) throw error;
            this.currentUser = null;
            this.userProfile = null;
            return { error: null };
        } catch (error) {
            console.error('Sign out error:', error);
            return { error };
        }
    }

    /**
     * Reset password (send reset email)
     */
    async resetPassword(email) {
        try {
            const { error } = await this.supabase.auth.resetPasswordForEmail(email, {
                redirectTo: `${window.location.origin}/assessments/auth/reset-password.html`
            });
            if (error) throw error;
            return { error: null };
        } catch (error) {
            console.error('Reset password error:', error);
            return { error };
        }
    }

    /**
     * Update password (after reset)
     */
    async updatePassword(newPassword) {
        try {
            const { error } = await this.supabase.auth.updateUser({
                password: newPassword
            });
            if (error) throw error;
            return { error: null };
        } catch (error) {
            console.error('Update password error:', error);
            return { error };
        }
    }

    /**
     * Link anonymous session to user account
     */
    async linkAnonymousSession(sessionId) {
        const user = await this.getCurrentUser();
        if (!user) {
            return { error: new Error('User not authenticated') };
        }

        try {
            // Find participant with this session_id
            const { data: participant, error: findError } = await this.supabase
                .from('participants')
                .select('id')
                .eq('session_id', sessionId)
                .is('user_id', null)
                .single();

            if (findError) {
                return { error: findError };
            }

            // Link participant to user
            const { error: updateError } = await this.supabase
                .from('participants')
                .update({ user_id: user.id })
                .eq('id', participant.id);

            if (updateError) {
                return { error: updateError };
            }

            return { error: null };
        } catch (error) {
            console.error('Link session error:', error);
            return { error };
        }
    }

    /**
     * Check if user is authenticated
     */
    async isAuthenticated() {
        const user = await this.getCurrentUser();
        return user !== null;
    }

    /**
     * Check if user has 2FA enabled (required for accessing assessments)
     */
    async require2FA() {
        const user = await this.getCurrentUser();
        if (!user) {
            return { required: false, has2FA: false, error: new Error('User not authenticated') };
        }

        const { enabled: has2FA, error } = await this.check2FAStatus();
        if (error) {
            return { required: true, has2FA: false, error };
        }

        return { required: true, has2FA: has2FA, error: null };
    }

    /**
     * Listen to auth state changes
     */
    onAuthStateChange(callback) {
        return this.supabase.auth.onAuthStateChange((event, session) => {
            this.currentUser = session?.user || null;
            callback(event, session);
        });
    }

    /**
     * Setup 2FA - Generate TOTP secret and QR code
     */
    async setup2FA() {
        try {
            const { data, error } = await this.supabase.auth.mfa.enroll({
                factorType: 'totp'
            });

            if (error) throw error;
            return { secret: data.secret, qrCode: data.qr_code, error: null };
        } catch (error) {
            console.error('2FA setup error:', error);
            return { secret: null, qrCode: null, error };
        }
    }

    /**
     * Verify 2FA code during setup
     */
    async verify2FASetup(code, factorId) {
        try {
            const { data, error } = await this.supabase.auth.mfa.verify({
                factorId: factorId,
                code: code
            });

            if (error) throw error;
            return { verified: true, error: null };
        } catch (error) {
            console.error('2FA verification error:', error);
            return { verified: false, error };
        }
    }

    /**
     * Challenge 2FA - Required after password login if 2FA is enabled
     */
    async challenge2FA() {
        try {
            const { data: factors } = await this.supabase.auth.mfa.listFactors();
            
            if (!factors || factors.totp.length === 0) {
                return { challengeId: null, error: new Error('No 2FA factors found') };
            }

            const totpFactor = factors.totp[0];
            const { data, error } = await this.supabase.auth.mfa.challenge({
                factorId: totpFactor.id
            });

            if (error) throw error;
            return { challengeId: data.id, error: null };
        } catch (error) {
            console.error('2FA challenge error:', error);
            return { challengeId: null, error };
        }
    }

    /**
     * Verify 2FA code during login
     */
    async verify2FALogin(challengeId, code) {
        try {
            const { data, error } = await this.supabase.auth.mfa.verify({
                challengeId: challengeId,
                code: code
            });

            if (error) throw error;
            return { verified: true, error: null };
        } catch (error) {
            console.error('2FA login verification error:', error);
            return { verified: false, error };
        }
    }

    /**
     * Check if user has 2FA enabled
     */
    async check2FAStatus() {
        try {
            const { data: factors, error } = await this.supabase.auth.mfa.listFactors();
            
            if (error) throw error;
            
            const has2FA = factors?.totp?.length > 0 && factors.totp[0].status === 'verified';
            return { enabled: has2FA, factors: factors, error: null };
        } catch (error) {
            console.error('2FA status check error:', error);
            return { enabled: false, factors: null, error };
        }
    }

    /**
     * Unenroll 2FA factor
     */
    async disable2FA(factorId) {
        try {
            const { error } = await this.supabase.auth.mfa.unenroll({
                factorId: factorId
            });

            if (error) throw error;
            return { error: null };
        } catch (error) {
            console.error('2FA disable error:', error);
            return { error };
        }
    }

    /**
     * Sign in with password - returns whether 2FA is required
     */
    async signInWithPassword(email, password) {
        try {
            const { data, error } = await this.supabase.auth.signInWithPassword({
                email,
                password
            });

            if (error) throw error;

            // Check if 2FA is required
            const { enabled: has2FA } = await this.check2FAStatus();
            
            if (has2FA) {
                // Challenge 2FA
                const { challengeId, error: challengeError } = await this.challenge2FA();
                if (challengeError) throw challengeError;
                
                return { 
                    user: data.user, 
                    requires2FA: true, 
                    challengeId: challengeId,
                    error: null 
                };
            }

            // Ensure user record exists in users table
            if (data.user) {
                const { data: userRecord } = await this.supabase
                    .from('users')
                    .select('id')
                    .eq('id', data.user.id)
                    .single();

                if (!userRecord) {
                    // Create user record if it doesn't exist
                    const { data: palLab } = await this.supabase
                        .from('labs')
                        .select('id')
                        .eq('name', 'PAL')
                        .single();

                    await this.supabase
                        .from('users')
                        .insert([{
                            id: data.user.id,
                            email: email,
                            full_name: data.user.user_metadata?.full_name || null,
                            lab_id: palLab?.id || null,
                            role: 'participant'
                        }]);
                }
            }

            this.currentUser = data.user;
            return { user: data.user, requires2FA: false, challengeId: null, error: null };
        } catch (error) {
            console.error('Sign in error:', error);
            return { user: null, requires2FA: false, challengeId: null, error };
        }
    }
}

// Export for use in other scripts
window.AuthManager = AuthManager;




