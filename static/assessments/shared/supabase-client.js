// Shared Supabase Client for Assessment Library
// Location: /static/assessments/shared/supabase-client.js
// Purpose: Centralized Supabase configuration and helper functions for all assessments
// Why: Provides consistent database access and session management across assessments
// RELEVANT FILES: static/assessments/library/index.html, supabase-schema.sql, scripts/export_assessment_data.R

// Supabase configuration - replace with your actual values
const SUPABASE_CONFIG = {
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY'
};

// Initialize Supabase client with auth enabled
const supabase = window.supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey, {
    auth: {
        persistSession: true,
        autoRefreshToken: true
    }
});

// Session management (supports both anonymous and authenticated users)
class AssessmentSession {
    constructor() {
        this.sessionId = this.getOrCreateSessionId();
        this.participantId = null;
        this.userId = null;
        this.initialized = false;
    }

    getOrCreateSessionId() {
        let sessionId = localStorage.getItem('assessment_session_id');
        if (!sessionId) {
            sessionId = 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            localStorage.setItem('assessment_session_id', sessionId);
        }
        return sessionId;
    }

    async initialize() {
        if (this.initialized) return this.participantId;

        try {
            // Check if user is authenticated first
            const { data: { user }, error: authError } = await supabase.auth.getUser();
            
            if (user && !authError) {
                // Authenticated user - check if user record exists
                let { data: userRecord, error: userError } = await supabase
                    .from('users')
                    .select('id')
                    .eq('id', user.id)
                    .single();

                if (userError && userError.code === 'PGRST116') {
                    // User record doesn't exist, create it
                    const { data: newUser, error: insertError } = await supabase
                        .from('users')
                        .insert([{
                            id: user.id,
                            email: user.email,
                            full_name: user.user_metadata?.full_name || null
                        }])
                        .select('id')
                        .single();

                    if (insertError) throw insertError;
                    userRecord = newUser;
                } else if (userError) {
                    throw userError;
                }

                this.userId = userRecord.id;

                // Get or create participant linked to user
                let { data: participant, error: participantError } = await supabase
                    .from('participants')
                    .select('id')
                    .eq('user_id', this.userId)
                    .single();

                if (participantError && participantError.code === 'PGRST116') {
                    // Participant doesn't exist, create new one linked to user
                    const { data: newParticipant, error: insertError } = await supabase
                        .from('participants')
                        .insert([{ 
                            session_id: this.sessionId,
                            user_id: this.userId
                        }])
                        .select('id')
                        .single();

                    if (insertError) throw insertError;
                    participant = newParticipant;
                } else if (participantError) {
                    throw participantError;
                }

                this.participantId = participant.id;
            } else {
                // Anonymous user - use session-based approach
                // Set session context for RLS
                await supabase.rpc('set_config', {
                    parameter: 'app.session_id',
                    value: this.sessionId
                }).catch(() => {
                    // RPC might not exist, continue anyway
                });

                // Get or create participant
                let { data: participant, error } = await supabase
                    .from('participants')
                    .select('id')
                    .eq('session_id', this.sessionId)
                    .single();

                if (error && error.code === 'PGRST116') {
                    // Participant doesn't exist, create new one
                    const { data: newParticipant, error: insertError } = await supabase
                        .from('participants')
                        .insert([{ session_id: this.sessionId }])
                        .select('id')
                        .single();

                    if (insertError) throw insertError;
                    participant = newParticipant;
                } else if (error) {
                    throw error;
                }

                this.participantId = participant.id;
            }

            this.initialized = true;
            return this.participantId;
        } catch (error) {
            console.error('Failed to initialize session:', error);
            throw error;
        }
    }

    async updateConsent(dataSharing = false, aiCoaching = false) {
        if (!this.participantId) await this.initialize();

        const { error } = await supabase
            .from('participants')
            .update({
                consent_data_sharing: dataSharing,
                consent_ai_coaching: aiCoaching
            })
            .eq('id', this.participantId);

        if (error) throw error;
    }

    async updateDemographics(demographics) {
        if (!this.participantId) await this.initialize();

        const { error } = await supabase
            .from('participants')
            .update({ demographics })
            .eq('id', this.participantId);

        if (error) throw error;
    }
}

// Assessment data management
class AssessmentData {
    constructor(assessmentName) {
        this.assessmentName = assessmentName;
        this.assessmentId = null;
        this.session = new AssessmentSession();
        this.startTime = Date.now();
    }

    async initialize() {
        await this.session.initialize();

        // Get assessment metadata
        const { data: assessment, error } = await supabase
            .from('assessments')
            .select('id, config')
            .eq('name', this.assessmentName)
            .eq('is_active', true)
            .single();

        if (error) throw error;
        this.assessmentId = assessment.id;
        this.config = assessment.config;
        return assessment;
    }

    async saveResponse(questionId, questionType, responseData, responseTime = null) {
        if (!this.assessmentId) await this.initialize();

        const response = {
            participant_id: this.session.participantId,
            assessment_id: this.assessmentId,
            question_id: questionId,
            question_type: questionType,
            response_data: responseData,
            response_time_ms: responseTime
        };

        const { data, error } = await supabase
            .from('responses')
            .insert([response])
            .select('id')
            .single();

        if (error) throw error;
        return data.id;
    }

    async saveResult(scores, feedback = null) {
        if (!this.assessmentId) await this.initialize();

        const completionTime = Date.now() - this.startTime;
        
        const result = {
            participant_id: this.session.participantId,
            assessment_id: this.assessmentId,
            scores,
            feedback,
            completion_time_ms: completionTime
        };

        const { data, error } = await supabase
            .from('results')
            .insert([result])
            .select('id')
            .single();

        if (error) throw error;
        return data.id;
    }

    async getParticipantResponses() {
        if (!this.assessmentId) await this.initialize();

        const { data, error } = await supabase
            .from('responses')
            .select('*')
            .eq('participant_id', this.session.participantId)
            .eq('assessment_id', this.assessmentId)
            .order('created_at', { ascending: true });

        if (error) throw error;
        return data;
    }

    async getParticipantResults() {
        if (!this.assessmentId) await this.initialize();

        const { data, error } = await supabase
            .from('results')
            .select('*')
            .eq('participant_id', this.session.participantId)
            .eq('assessment_id', this.assessmentId)
            .order('completed_at', { ascending: false });

        if (error) throw error;
        return data;
    }
}

// Utility functions
const AssessmentUtils = {
    // Generate unique question ID
    generateQuestionId: (prefix, index) => `${prefix}_q${String(index).padStart(3, '0')}`,

    // Format response time
    formatResponseTime: (milliseconds) => {
        if (milliseconds < 1000) return `${milliseconds}ms`;
        if (milliseconds < 60000) return `${(milliseconds / 1000).toFixed(1)}s`;
        return `${(milliseconds / 60000).toFixed(1)}m`;
    },

    // Validate response data
    validateResponse: (questionType, responseData) => {
        switch (questionType) {
            case 'mcq':
                return responseData.hasOwnProperty('selected') && 
                       typeof responseData.selected === 'number';
            
            case 'multiple_answer':
                return responseData.hasOwnProperty('selected') && 
                       Array.isArray(responseData.selected);
            
            case 'likert':
                return responseData.hasOwnProperty('value') && 
                       typeof responseData.value === 'number' &&
                       responseData.value >= 1 && responseData.value <= 7;
            
            case 'conjoint_choice':
                return responseData.hasOwnProperty('chosen_alternative') &&
                       typeof responseData.chosen_alternative === 'number';
            
            case 'text':
                return responseData.hasOwnProperty('text') &&
                       typeof responseData.text === 'string';
            
            default:
                return false;
        }
    },

    // Calculate percentile rank
    calculatePercentile: (score, scores) => {
        const sorted = scores.sort((a, b) => a - b);
        const rank = sorted.filter(s => s < score).length;
        return Math.round((rank / sorted.length) * 100);
    },

    // Generate feedback based on score
    generateFeedback: (score, scale, feedbackRules) => {
        for (const rule of feedbackRules) {
            if (score >= rule.min && score <= rule.max) {
                return rule.feedback;
            }
        }
        return "Thank you for completing the assessment.";
    }
};

// Error handling
const AssessmentError = {
    handle: (error, context = '') => {
        console.error(`Assessment Error ${context}:`, error);
        
        // User-friendly error messages
        const userMessage = (() => {
            if (error.message?.includes('network')) {
                return 'Network connection issue. Please check your internet connection and try again.';
            }
            if (error.message?.includes('unauthorized')) {
                return 'Session expired. Please refresh the page and try again.';
            }
            if (error.code === 'PGRST116') {
                return 'Data not found. This may be a temporary issue.';
            }
            return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
        })();

        return {
            technical: error.message,
            user: userMessage,
            code: error.code || 'UNKNOWN'
        };
    },

    show: (error, elementId = null) => {
        const errorInfo = AssessmentError.handle(error);
        const message = `⚠️ ${errorInfo.user}`;
        
        if (elementId) {
            const element = document.getElementById(elementId);
            if (element) {
                element.innerHTML = `<div class="error-message" style="color: #dc3545; padding: 1rem; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 4px; margin: 1rem 0;">${message}</div>`;
            }
        } else {
            alert(message);
        }
    }
};

// Export for use in other scripts
window.AssessmentLibrary = {
    supabase,
    AssessmentSession,
    AssessmentData,
    AssessmentUtils,
    AssessmentError,
    SUPABASE_CONFIG
};
