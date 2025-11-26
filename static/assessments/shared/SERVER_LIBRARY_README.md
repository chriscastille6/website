# Assessment Server Library

## Overview

The Assessment Server Library provides a unified interface for all server-side assessment functionality. It consolidates database access, authentication, access control, and other core services into a single, easy-to-use API.

## Location

`/static/assessments/shared/server-library.js`

## Architecture

The server library consolidates these components:

- **Supabase Client** - Database access and real-time subscriptions
- **Session Management** - Anonymous and authenticated session handling
- **Authentication** - User login, registration, password management
- **Access Control** - Lab-based permissions and assessment access
- **AI Coaching** - AI-powered coaching generation (when enabled)
- **SONA Integration** - Research study tracking and IRB access
- **Assessment Runner** - Standardized assessment execution
- **Participant ID Generator** - Deterministic participant ID generation

## Quick Start

### 1. Include Required Scripts

```html
<!-- Supabase client -->
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>

<!-- Server library components (load in order) -->
<script src="/assessments/shared/supabase-client.js"></script>
<script src="/assessments/shared/auth-manager.js"></script>
<script src="/assessments/shared/access-control.js"></script>
<script src="/assessments/shared/ai-coaching.js"></script>
<script src="/assessments/shared/sona-integration.js"></script>
<script src="/assessments/shared/participant-id-generator.js"></script>
<script src="/assessments/shared/assessment-runner.js"></script>

<!-- Main server library (load last) -->
<script src="/assessments/shared/server-library.js"></script>
```

### 2. Initialize the Library

```javascript
// Get the default library instance
const library = await getAssessmentLibrary({
    supabaseUrl: 'YOUR_SUPABASE_URL',
    supabaseKey: 'YOUR_SUPABASE_ANON_KEY'
});

// Or create a custom instance
const customLibrary = new AssessmentServerLibrary({
    supabaseUrl: 'YOUR_SUPABASE_URL',
    supabaseKey: 'YOUR_SUPABASE_ANON_KEY'
});
await customLibrary.initialize();
```

### 3. Use the Library

```javascript
// Check authentication
const isAuth = await library.isAuthenticated();

// Get current user
const user = await library.getCurrentUser();

// Check access to an assessment
const access = await library.canAccessAssessment('personality-test');
if (access.canAccess) {
    // User can access this assessment
}

// Get all accessible assessments
const assessments = await library.getAccessibleAssessments();

// Generate participant ID
const participantId = library.generateParticipantId('John Doe');

// Get session ID
const sessionId = library.getSessionId();
```

## API Reference

### Core Methods

#### `initialize()`
Initialize the library and all components. Called automatically when using `getAssessmentLibrary()`.

#### `getCurrentUser()`
Get the currently authenticated user.

**Returns:** `Promise<User | null>`

#### `isAuthenticated()`
Check if a user is currently authenticated.

**Returns:** `Promise<boolean>`

#### `canAccessAssessment(assessmentName)`
Check if the current user can access a specific assessment.

**Parameters:**
- `assessmentName` (string) - Name of the assessment

**Returns:** `Promise<{canAccess: boolean, reason: string}>`

#### `getAccessibleAssessments()`
Get all assessments the current user can access.

**Returns:** `Promise<Array<Assessment>>`

#### `isAdmin()`
Check if the current user is an admin.

**Returns:** `Promise<boolean>`

#### `isResearcher()`
Check if the current user is a researcher or admin.

**Returns:** `Promise<boolean>`

#### `generateParticipantId(name)`
Generate a deterministic participant ID from a name.

**Parameters:**
- `name` (string) - Full name

**Returns:** `string` - Participant ID in format `CANDIDATE-XXXX-XXXX`

#### `getSessionId()`
Get or create the current session ID.

**Returns:** `string` - Session ID

#### `clearCache()`
Clear all caches (useful after permission changes).

#### `getStatus()`
Get the initialization status and component availability.

**Returns:** `Object` with `initialized` and `components` properties

### Component Access

You can also access individual components directly:

```javascript
// Authentication
await library.auth.signIn(email, password);
await library.auth.signUp(email, password, fullName);
await library.auth.signOut();

// Access Control
const canAccess = await library.access.canAccessAssessment('ei-test');
const assessments = await library.access.getAccessibleAssessments();

// AI Coaching (when enabled)
if (library.coaching.isEnabled()) {
    const coaching = await library.coaching.generateCoaching(result, 'ei');
}

// SONA Integration
await library.sona.registerStudy(sonaId, irbNumber, title, pi);
await library.sona.linkParticipantToStudy(studyId, participantId);

// Direct Supabase access
const { data } = await library.supabase
    .from('assessments')
    .select('*');
```

## Usage Examples

### Example 1: Check Access Before Loading Assessment

```javascript
const library = await getAssessmentLibrary();

const access = await library.canAccessAssessment('personality-test');
if (!access.canAccess) {
    alert('You do not have access to this assessment.');
    return;
}

// Load assessment...
```

### Example 2: Authenticate User

```javascript
const library = await getAssessmentLibrary();

// Sign in
const { user, error } = await library.auth.signIn(email, password);
if (error) {
    console.error('Sign in failed:', error);
    return;
}

// User is now authenticated
const isAuth = await library.isAuthenticated(); // true
```

### Example 3: Get User's Assessment History

```javascript
const library = await getAssessmentLibrary();
const user = await library.getCurrentUser();

if (user) {
    const { data: results } = await library.supabase
        .from('results')
        .select(`
            *,
            assessments (name, title),
            participants (participant_id)
        `)
        .eq('participants.user_id', user.id)
        .order('created_at', { ascending: false });
    
    console.log('Assessment history:', results);
}
```

### Example 4: Generate Coaching (When Enabled)

```javascript
const library = await getAssessmentLibrary();

if (library.coaching && library.coaching.isEnabled()) {
    const coaching = await library.coaching.generateCoaching(
        assessmentResult,
        'ei'
    );
    
    // Save coaching session
    await library.coaching.saveCoachingSession(
        participantId,
        resultId,
        coaching
    );
}
```

## Error Handling

The library throws errors for initialization failures. Always wrap initialization in try-catch:

```javascript
try {
    const library = await getAssessmentLibrary();
} catch (error) {
    console.error('Failed to initialize library:', error);
    // Handle error (show message to user, etc.)
}
```

## Backward Compatibility

The library maintains backward compatibility with anonymous sessions. If no user is authenticated, it falls back to anonymous session-based participation.

## Dependencies

- Supabase JS Client (`@supabase/supabase-js`)
- All shared library components (loaded before server-library.js)

## Related Files

- `supabase-client.js` - Core database client
- `auth-manager.js` - Authentication management
- `access-control.js` - Access control utilities
- `ai-coaching.js` - AI coaching integration
- `sona-integration.js` - SONA study integration
- `assessment-runner.js` - Assessment execution
- `participant-id-generator.js` - Participant ID generation


