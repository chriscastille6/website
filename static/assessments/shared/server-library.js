// Assessment Server Library - Main Entry Point
// Location: /static/assessments/shared/server-library.js
// Purpose: Unified server library that consolidates all assessment system components
// Why: Provides a single entry point for all server-side functionality (database, auth, access control, etc.)
// RELEVANT FILES: supabase-client.js, auth-manager.js, access-control.js, assessment-runner.js, ai-coaching.js

/**
 * Assessment Server Library
 * 
 * This is the main entry point for all server-side assessment functionality.
 * It consolidates:
 * - Database access (Supabase client)
 * - Authentication (AuthManager)
 * - Access control (AccessControl)
 * - Assessment running (AssessmentRunner)
 * - AI coaching (AICoaching)
 * - SONA integration (SONAIntegration)
 * - Participant ID generation (ParticipantIdGenerator)
 * 
 * Usage:
 *   const library = new AssessmentServerLibrary();
 *   await library.initialize();
 *   const user = await library.auth.getCurrentUser();
 */

class AssessmentServerLibrary {
    constructor(config = {}) {
        // Configuration
        this.config = {
            supabaseUrl: config.supabaseUrl || window.AssessmentLibrary?.SUPABASE_CONFIG?.url || 'YOUR_SUPABASE_URL',
            supabaseKey: config.supabaseKey || window.AssessmentLibrary?.SUPABASE_CONFIG?.anonKey || 'YOUR_SUPABASE_ANON_KEY',
            ...config
        };

        // Core components (will be initialized)
        this.supabase = null;
        this.session = null;
        this.auth = null;
        this.access = null;
        this.coaching = null;
        this.sona = null;
        this.runner = null;

        // State
        this.initialized = false;
    }

    /**
     * Initialize the server library
     * Loads all components and sets up connections
     */
    async initialize() {
        if (this.initialized) {
            return this;
        }

        try {
            // Initialize Supabase client
            if (typeof window.supabase !== 'undefined') {
                this.supabase = window.supabase.createClient(
                    this.config.supabaseUrl,
                    this.config.supabaseKey,
                    {
                        auth: {
                            persistSession: true,
                            autoRefreshToken: true
                        }
                    }
                );
            } else {
                throw new Error('Supabase client library not loaded. Include <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>');
            }

            // Initialize session management
            if (window.AssessmentSession) {
                this.session = new window.AssessmentSession();
                await this.session.initialize();
            }

            // Initialize authentication manager
            if (window.AuthManager) {
                this.auth = new window.AuthManager();
            }

            // Initialize access control
            if (window.AccessControl) {
                this.access = new window.AccessControl(this.supabase);
            }

            // Initialize AI coaching
            if (window.AICoaching) {
                this.coaching = new window.AICoaching(this.supabase);
            }

            // Initialize SONA integration
            if (window.SONAIntegration) {
                this.sona = new window.SONAIntegration(this.supabase);
            }

            // Initialize assessment runner (if available)
            if (window.AssessmentRunner) {
                this.runner = new window.AssessmentRunner(this.supabase);
            }

            this.initialized = true;
            return this;
        } catch (error) {
            console.error('Error initializing Assessment Server Library:', error);
            throw error;
        }
    }

    /**
     * Get current user (convenience method)
     */
    async getCurrentUser() {
        if (!this.initialized) await this.initialize();
        if (this.auth) {
            return await this.auth.getCurrentUser();
        }
        return null;
    }

    /**
     * Check if user can access an assessment
     */
    async canAccessAssessment(assessmentName) {
        if (!this.initialized) await this.initialize();
        if (this.access) {
            return await this.access.canAccessAssessment(assessmentName);
        }
        // Default: allow access if access control not available
        return { canAccess: true, reason: 'no_access_control' };
    }

    /**
     * Get all accessible assessments
     */
    async getAccessibleAssessments() {
        if (!this.initialized) await this.initialize();
        if (this.access) {
            return await this.access.getAccessibleAssessments();
        }
        // Fallback: get all active assessments
        const { data } = await this.supabase
            .from('assessments')
            .select('*')
            .eq('is_active', true);
        return data || [];
    }

    /**
     * Check if user is authenticated
     */
    async isAuthenticated() {
        if (!this.initialized) await this.initialize();
        if (this.auth) {
            return await this.auth.isAuthenticated();
        }
        const { data: { user } } = await this.supabase.auth.getUser();
        return user !== null;
    }

    /**
     * Check if user is admin
     */
    async isAdmin() {
        if (!this.initialized) await this.initialize();
        if (this.access) {
            return await this.access.isAdmin();
        }
        return false;
    }

    /**
     * Check if user is researcher
     */
    async isResearcher() {
        if (!this.initialized) await this.initialize();
        if (this.access) {
            return await this.access.isResearcher();
        }
        return false;
    }

    /**
     * Generate participant ID from name
     */
    generateParticipantId(name) {
        if (window.ParticipantIdGenerator) {
            return window.ParticipantIdGenerator.generate(name);
        }
        // Fallback: simple hash
        return 'PART-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
    }

    /**
     * Get current session ID
     */
    getSessionId() {
        if (this.session) {
            return this.session.sessionId;
        }
        // Fallback: get from localStorage
        let sessionId = localStorage.getItem('assessment_session_id');
        if (!sessionId) {
            sessionId = 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            localStorage.setItem('assessment_session_id', sessionId);
        }
        return sessionId;
    }

    /**
     * Clear all caches (useful after permission changes)
     */
    clearCache() {
        if (this.access) {
            this.access.clearCache();
        }
        if (this.session) {
            this.session = null;
        }
        if (this.auth) {
            this.auth.currentUser = null;
            this.auth.userProfile = null;
        }
    }

    /**
     * Get library status
     */
    getStatus() {
        return {
            initialized: this.initialized,
            components: {
                supabase: this.supabase !== null,
                session: this.session !== null,
                auth: this.auth !== null,
                access: this.access !== null,
                coaching: this.coaching !== null,
                sona: this.sona !== null,
                runner: this.runner !== null
            }
        };
    }
}

// Export for use in other scripts
window.AssessmentServerLibrary = AssessmentServerLibrary;

// Create a default instance (singleton pattern)
window.assessmentLibrary = null;

/**
 * Get or create the default library instance
 */
window.getAssessmentLibrary = async function(config) {
    if (!window.assessmentLibrary) {
        window.assessmentLibrary = new AssessmentServerLibrary(config);
        await window.assessmentLibrary.initialize();
    }
    return window.assessmentLibrary;
};


