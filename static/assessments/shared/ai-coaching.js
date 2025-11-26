// AI Coaching Integration
// Location: /static/assessments/shared/ai-coaching.js
// Purpose: OpenAI API integration for generating coaching insights from assessment scores
// Why: Provides personalized coaching based on assessment results (prepared for future rollout)
// RELEVANT FILES: supabase-schema.sql, static/assessments/coaching/dashboard.html
// NOTE: This is prepared for future rollout but currently disabled

/**
 * AI Coaching Manager
 * Handles OpenAI API calls for generating coaching insights
 * Currently disabled - will be enabled in future rollout
 */
class AICoaching {
    constructor(supabase) {
        this.supabase = supabase;
        this.openaiApiKey = null; // Set from environment variable
        this.coachingEnabled = false; // Disabled until rollout
    }

    /**
     * Check if coaching is enabled
     */
    isEnabled() {
        return this.coachingEnabled;
    }

    /**
     * Generate coaching insights from assessment results
     * Focuses on EI four branches: perceiving, using, understanding, managing emotions
     * 
     * @param {Object} assessmentResult - Assessment result with scores
     * @param {string} assessmentType - Type of assessment (ei, personality, etc.)
     * @returns {Promise<Object>} - Coaching insights and recommendations
     */
    async generateCoaching(assessmentResult, assessmentType) {
        if (!this.isEnabled()) {
            throw new Error('AI coaching is not yet available');
        }

        // Prepare context: summarize scores on EI facets and percentiles
        const context = this.prepareCoachingContext(assessmentResult, assessmentType);

        // Generate prompt for OpenAI
        const prompt = this.buildCoachingPrompt(context, assessmentType);

        try {
            // Call OpenAI API (disabled for now)
            // const response = await this.callOpenAI(prompt);
            // return this.parseCoachingResponse(response);

            // Placeholder for future implementation
            return {
                insights: [],
                recommendations: [],
                message: 'AI coaching will be available in a future update'
            };
        } catch (error) {
            console.error('Error generating coaching:', error);
            throw error;
        }
    }

    /**
     * Prepare coaching context from assessment scores
     * Focuses on EI facets: perceiving, using, understanding, managing emotions
     */
    prepareCoachingContext(assessmentResult, assessmentType) {
        const scores = assessmentResult.scores || {};
        const context = {
            assessmentType,
            scores: {},
            percentiles: {},
            facets: {}
        };

        if (assessmentType === 'ei') {
            // EI four branches
            context.facets = {
                perceiving: scores.perceiving || 0,
                using: scores.using || 0,
                understanding: scores.understanding || 0,
                managing: scores.managing || 0
            };
            context.percentiles = scores.percentiles || {};
        } else if (assessmentType === 'personality') {
            // Big Five
            context.facets = {
                openness: scores.openness || 0,
                conscientiousness: scores.conscientiousness || 0,
                extraversion: scores.extraversion || 0,
                agreeableness: scores.agreeableness || 0,
                neuroticism: scores.neuroticism || 0
            };
        }

        return context;
    }

    /**
     * Build coaching prompt for OpenAI
     */
    buildCoachingPrompt(context, assessmentType) {
        let prompt = `You are a supportive workplace coach providing personalized feedback based on assessment results.\n\n`;

        if (assessmentType === 'ei') {
            prompt += `The participant completed an Emotional Intelligence assessment measuring four branches:\n`;
            prompt += `- Perceiving emotions: ${context.facets.perceiving}\n`;
            prompt += `- Using emotions: ${context.facets.using}\n`;
            prompt += `- Understanding emotions: ${context.facets.understanding}\n`;
            prompt += `- Managing emotions: ${context.facets.managing}\n\n`;
            
            if (context.percentiles && Object.keys(context.percentiles).length > 0) {
                prompt += `Percentile scores:\n`;
                Object.entries(context.percentiles).forEach(([facet, percentile]) => {
                    prompt += `- ${facet}: ${percentile}th percentile\n`;
                });
                prompt += `\n`;
            }

            prompt += `Provide supportive, actionable coaching insights focusing on:\n`;
            prompt += `1. Strengths in emotional intelligence\n`;
            prompt += `2. Areas for development\n`;
            prompt += `3. Specific, actionable recommendations for improvement\n`;
            prompt += `4. Workplace applications\n\n`;
            prompt += `Use a supportive, encouraging tone.`;
        } else {
            prompt += `Provide personalized coaching based on the assessment results.`;
        }

        return prompt;
    }

    /**
     * Call OpenAI API (placeholder - will be implemented in rollout)
     */
    async callOpenAI(prompt) {
        // TODO: Implement OpenAI API call when enabled
        // const response = await fetch('https://api.openai.com/v1/chat/completions', {
        //   method: 'POST',
        //   headers: {
        //     'Content-Type': 'application/json',
        //     'Authorization': `Bearer ${this.openaiApiKey}`
        //   },
        //   body: JSON.stringify({
        //     model: 'gpt-4',
        //     messages: [{ role: 'user', content: prompt }],
        //     temperature: 0.7
        //   })
        // });
        // return await response.json();
        throw new Error('OpenAI integration not yet implemented');
    }

    /**
     * Parse OpenAI response into structured coaching data
     */
    parseCoachingResponse(openaiResponse) {
        // TODO: Parse OpenAI response when implemented
        return {
            insights: [],
            recommendations: []
        };
    }

    /**
     * Save coaching session to database
     */
    async saveCoachingSession(participantId, assessmentResultId, coachingData) {
        const { data, error } = await this.supabase
            .from('coaching_sessions')
            .insert([{
                participant_id: participantId,
                assessment_result_id: assessmentResultId,
                session_type: 'assessment_coaching',
                coaching_type: 'general',
                session_data: coachingData,
                insights: coachingData.insights,
                recommendations: coachingData.recommendations,
                ai_model: 'gpt-4'
            }])
            .select()
            .single();

        if (error) throw error;
        return data;
    }
}

// Export for use in other scripts
window.AICoaching = AICoaching;




