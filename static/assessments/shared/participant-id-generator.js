// Participant ID Generator
// Location: /static/assessments/shared/participant-id-generator.js
// Purpose: Generate deterministic participant IDs from names for research tagging
// Why: Provides consistent participant IDs without storing names in the database
// RELEVANT FILES: cnjoint analysis/candidate_id_generator_standalone.html, supabase-schema.sql

// CANDIDATE-ID Generator (adapted from CANDIDATE tool)
// Based on: https://github.com/chriscastille6/CANDIDATE-ID-GENERATOR
// Original: https://github.com/frode-sandnes/CANDIDATE

/**
 * Generate a deterministic participant ID from a name
 * Same name always generates same ID (deterministic hash)
 * Name is never stored - only the ID is saved
 * 
 * @param {string} name - Full name (first and last)
 * @returns {string|null} - Participant ID in format CANDIDATE-XXXX-XXXX or null if invalid
 */
function generateParticipantId(name) {
    if (!name || name.trim() === '') {
        return null;
    }
    
    // Normalize the name: trim, lowercase, remove extra spaces
    const normalized = name.trim().toLowerCase().replace(/\s+/g, ' ');
    
    // Simple hash function to create consistent ID
    let hash = 0;
    for (let i = 0; i < normalized.length; i++) {
        const char = normalized.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32-bit integer
    }
    
    // Convert to positive number and create alphanumeric ID
    const absHash = Math.abs(hash);
    const base36 = absHash.toString(36).toUpperCase();
    
    // Pad to ensure consistent length (8 characters)
    const padded = base36.padStart(8, '0');
    
    // Format as CANDIDATE-XXXX-XXXX
    const formatted = `CANDIDATE-${padded.substring(0, 4)}-${padded.substring(4, 8)}`;
    
    return formatted;
}

/**
 * Store participant ID in localStorage (for persistence across sessions)
 * Also stores normalized name hash for verification (not the actual name)
 * 
 * @param {string} participantId - The generated participant ID
 * @param {string} name - The original name (for hash verification)
 */
function storeParticipantId(participantId, name) {
    if (!participantId || !name) return;
    
    localStorage.setItem('participant_id', participantId);
    // Store normalized name hash for verification (not the actual name)
    localStorage.setItem('participant_name_hash', name.toLowerCase().trim());
}

/**
 * Retrieve stored participant ID from localStorage
 * 
 * @returns {string|null} - Stored participant ID or null if not found
 */
function getStoredParticipantId() {
    return localStorage.getItem('participant_id');
}

/**
 * Verify that a stored participant ID matches the provided name
 * 
 * @param {string} name - Name to verify against stored ID
 * @returns {boolean} - True if stored ID matches generated ID from name
 */
function verifyParticipantId(name) {
    const storedId = getStoredParticipantId();
    if (!storedId || !name) return false;
    
    const generatedId = generateParticipantId(name);
    return storedId === generatedId;
}

// Export for use in other scripts
window.ParticipantIdGenerator = {
    generate: generateParticipantId,
    store: storeParticipantId,
    get: getStoredParticipantId,
    verify: verifyParticipantId
};




