// SONA Integration Utilities
// Location: /static/assessments/shared/sona-integration.js
// Purpose: Utilities for linking assessments to SONA studies and tracking participant completion
// Why: Enables IRB access to study records and assessment data
// RELEVANT FILES: supabase-schema.sql, static/assessments/admin/sona-studies.html

/**
 * SONA Integration Manager
 * Handles linking assessments to studies and tracking participant completion
 */
class SONAIntegration {
    constructor(supabase) {
        this.supabase = supabase;
    }

    /**
     * Register a study in the assessment library
     * @param {string} sonaStudyId - Study ID from SONA system
     * @param {string} irbApprovalNumber - IRB approval number
     * @param {string} title - Study title
     * @param {string} principalInvestigator - PI name
     * @returns {Promise<Object>} - Created study record
     */
    async registerStudy(sonaStudyId, irbApprovalNumber, title, principalInvestigator) {
        const { data, error } = await this.supabase
            .from('sona_studies')
            .insert([{
                sona_study_id: sonaStudyId,
                irb_approval_number: irbApprovalNumber,
                title: title,
                principal_investigator: principalInvestigator,
                status: 'active'
            }])
            .select()
            .single();

        if (error) throw error;
        return data;
    }

    /**
     * Assign assessments to a study
     * @param {string} studyId - Study UUID
     * @param {Array<string>} assessmentIds - Array of assessment UUIDs
     * @returns {Promise<Array>} - Created study_assessments records
     */
    async assignAssessmentsToStudy(studyId, assessmentIds) {
        const studyAssessments = assessmentIds.map(assessmentId => ({
            study_id: studyId,
            assessment_id: assessmentId,
            is_required: false
        }));

        const { data, error } = await this.supabase
            .from('study_assessments')
            .insert(studyAssessments)
            .select();

        if (error) throw error;
        return data;
    }

    /**
     * Link participant to study (when they complete assessment for a study)
     * @param {string} studyId - Study UUID
     * @param {string} participantId - Participant UUID
     * @returns {Promise<Object>} - Created study_participants record
     */
    async linkParticipantToStudy(studyId, participantId) {
        const { data, error } = await this.supabase
            .from('study_participants')
            .insert([{
                study_id: studyId,
                participant_id: participantId,
                completed_at: new Date().toISOString()
            }])
            .select()
            .single();

        if (error && error.code !== '23505') { // Ignore duplicate key errors
            throw error;
        }

        return data;
    }

    /**
     * Get study by SONA study ID and IRB number
     * @param {string} sonaStudyId - Study ID from SONA
     * @param {string} irbApprovalNumber - IRB approval number
     * @returns {Promise<Object>} - Study record
     */
    async getStudy(sonaStudyId, irbApprovalNumber) {
        const { data, error } = await this.supabase
            .from('sona_studies')
            .select('*')
            .eq('sona_study_id', sonaStudyId)
            .eq('irb_approval_number', irbApprovalNumber)
            .single();

        if (error) throw error;
        return data;
    }

    /**
     * Get all participants for a study (for IRB access)
     * @param {string} studyId - Study UUID
     * @returns {Promise<Array>} - Participant records (anonymized - participant IDs only)
     */
    async getStudyParticipants(studyId) {
        const { data, error } = await this.supabase
            .from('study_participants')
            .select(`
                *,
                participants (
                    participant_id,
                    created_at
                )
            `)
            .eq('study_id', studyId);

        if (error) throw error;
        return data;
    }

    /**
     * Get assessment results for a study (for IRB access)
     * @param {string} studyId - Study UUID
     * @returns {Promise<Array>} - Assessment results (anonymized)
     */
    async getStudyResults(studyId) {
        // Get participants in study
        const { data: studyParticipants } = await this.supabase
            .from('study_participants')
            .select('participant_id')
            .eq('study_id', studyId);

        if (!studyParticipants || studyParticipants.length === 0) {
            return [];
        }

        const participantIds = studyParticipants.map(sp => sp.participant_id);

        // Get assessments used in study
        const { data: studyAssessments } = await this.supabase
            .from('study_assessments')
            .select('assessment_id')
            .eq('study_id', studyId);

        if (!studyAssessments || studyAssessments.length === 0) {
            return [];
        }

        const assessmentIds = studyAssessments.map(sa => sa.assessment_id);

        // Get results
        const { data: results, error } = await this.supabase
            .from('results')
            .select(`
                *,
                assessments (
                    name,
                    title
                ),
                participants (
                    participant_id
                )
            `)
            .in('participant_id', participantIds)
            .in('assessment_id', assessmentIds);

        if (error) throw error;
        return results;
    }

    /**
     * Log IRB access (for audit trail)
     * @param {string} studyId - Study UUID
     * @param {string} accessType - Type of access (view, export, report)
     * @param {string} accessedBy - User identifier
     */
    async logIRBAccess(studyId, accessType, accessedBy) {
        const { error } = await this.supabase
            .from('irb_access_log')
            .insert([{
                study_id: studyId,
                access_type: accessType,
                accessed_by: accessedBy
            }]);

        if (error) throw error;
    }
}

// Export for use in other scripts
window.SONAIntegration = SONAIntegration;




