// Access Control Utilities
// Location: /static/assessments/shared/access-control.js
// Purpose: Check user access to assessments based on lab membership and permissions
// Why: Provides lab-based access control for assessments
// RELEVANT FILES: static/assessments/library/index.html, supabase-schema.sql

/**
 * Access Control Manager
 * Handles checking user permissions for assessments
 */
class AccessControl {
    constructor(supabase) {
        this.supabase = supabase;
        this.userCache = null;
        this.permissionsCache = null;
    }

    /**
     * Get current user's lab and role
     */
    async getCurrentUser() {
        if (this.userCache) return this.userCache;

        const { data: { user } } = await this.supabase.auth.getUser();
        if (!user) {
            this.userCache = null;
            return null;
        }

        const { data: userRecord } = await this.supabase
            .from('users')
            .select('id, lab_id, role')
            .eq('id', user.id)
            .single();

        this.userCache = userRecord;
        return userRecord;
    }

    /**
     * Check if user can access a specific assessment
     * @param {string} assessmentName - Name of the assessment
     * @returns {Promise<{canAccess: boolean, reason: string}>}
     */
    async canAccessAssessment(assessmentName) {
        const user = await this.getCurrentUser();

        // Anonymous users can access public assessments (backward compatibility)
        if (!user) {
            return { canAccess: true, reason: 'anonymous' };
        }

        // Admins can access everything
        if (user.role === 'admin') {
            return { canAccess: true, reason: 'admin' };
        }

        // Get assessment ID
        const { data: assessment } = await this.supabase
            .from('assessments')
            .select('id')
            .eq('name', assessmentName)
            .eq('is_active', true)
            .single();

        if (!assessment) {
            return { canAccess: false, reason: 'assessment_not_found' };
        }

        // Check individual user permission override
        const { data: userPermission } = await this.supabase
            .from('user_assessments')
            .select('*')
            .eq('user_id', user.id)
            .eq('assessment_id', assessment.id)
            .is('expires_at', null)
            .single();

        if (userPermission) {
            return { canAccess: true, reason: 'individual_permission' };
        }

        // Check if user's lab has access
        if (user.lab_id) {
            const { data: labAccess } = await this.supabase
                .from('lab_assessments')
                .select('*')
                .eq('lab_id', user.lab_id)
                .eq('assessment_id', assessment.id)
                .eq('is_active', true)
                .single();

            if (labAccess) {
                return { 
                    canAccess: true, 
                    reason: 'lab_access',
                    accessLevel: labAccess.access_level
                };
            }
        }

        return { canAccess: false, reason: 'no_access' };
    }

    /**
     * Get all assessments user can access
     * @returns {Promise<Array>} - List of accessible assessments
     */
    async getAccessibleAssessments() {
        const user = await this.getCurrentUser();

        // Anonymous users can see all active assessments (backward compatibility)
        if (!user) {
            const { data: assessments } = await this.supabase
                .from('assessments')
                .select('*')
                .eq('is_active', true);
            return assessments || [];
        }

        // Admins can see everything
        if (user.role === 'admin') {
            const { data: assessments } = await this.supabase
                .from('assessments')
                .select('*')
                .eq('is_active', true);
            return assessments || [];
        }

        // Get assessments via lab access
        let accessibleAssessmentIds = [];

        if (user.lab_id) {
            const { data: labAssessments } = await this.supabase
                .from('lab_assessments')
                .select('assessment_id')
                .eq('lab_id', user.lab_id)
                .eq('is_active', true);

            if (labAssessments) {
                accessibleAssessmentIds = labAssessments.map(la => la.assessment_id);
            }
        }

        // Get assessments via individual permissions
        const { data: userAssessments } = await this.supabase
            .from('user_assessments')
            .select('assessment_id')
            .eq('user_id', user.id)
            .or('expires_at.is.null,expires_at.gt.' + new Date().toISOString());

        if (userAssessments) {
            const userAssessmentIds = userAssessments.map(ua => ua.assessment_id);
            accessibleAssessmentIds = [...new Set([...accessibleAssessmentIds, ...userAssessmentIds])];
        }

        if (accessibleAssessmentIds.length === 0) {
            return [];
        }

        // Get full assessment details
        const { data: assessments } = await this.supabase
            .from('assessments')
            .select('*')
            .in('id', accessibleAssessmentIds)
            .eq('is_active', true);

        return assessments || [];
    }

    /**
     * Check if user is admin
     */
    async isAdmin() {
        const user = await this.getCurrentUser();
        return user && user.role === 'admin';
    }

    /**
     * Check if user is researcher
     */
    async isResearcher() {
        const user = await this.getCurrentUser();
        return user && (user.role === 'admin' || user.role === 'researcher');
    }

    /**
     * Clear cache (call after user permissions change)
     */
    clearCache() {
        this.userCache = null;
        this.permissionsCache = null;
    }
}

// Export for use in other scripts
window.AccessControl = AccessControl;




