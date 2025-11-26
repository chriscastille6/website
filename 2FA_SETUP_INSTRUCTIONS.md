# 2FA Setup Instructions
# Location: /Users/ccastille/Documents/GitHub/Website/2FA_SETUP_INSTRUCTIONS.md
# Purpose: Instructions for enabling 2FA in Supabase and using it in the assessment library
# Why: Provides clear guidance for setting up two-factor authentication
# RELEVANT FILES: static/assessments/shared/auth-manager.js, static/assessments/auth/setup-2fa.html

## Overview

Two-factor authentication (2FA) is now **required** for accessing:
- Assessments
- Assessment results
- AI coaching features

Users must set up 2FA after creating an account or they will be prompted to do so when accessing protected features.

## Supabase Configuration

### Enable MFA in Supabase Dashboard

1. **Go to Supabase Dashboard:**
   - Navigate to your project
   - Go to **Authentication** → **Settings**

2. **Enable Multi-Factor Authentication:**
   - Find "Multi-Factor Authentication" section
   - Enable "Time-based One-Time Password (TOTP)"
   - Save changes

3. **Configure MFA Settings (Optional):**
   - Set issuer name (e.g., "Assessment Library")
   - Configure MFA factors (TOTP is the default)

## User Flow

### New User Registration

1. User creates account at `/assessments/auth/register.html`
2. After registration, user is automatically redirected to `/assessments/auth/setup-2fa.html?required=true`
3. User scans QR code with authenticator app (Google Authenticator, Authy, etc.)
4. User verifies setup with 6-digit code
5. 2FA is enabled and user can access assessments

### Existing User Login

1. User signs in at `/assessments/auth/login.html` with email and password
2. If 2FA is enabled:
   - User is redirected to `/assessments/auth/verify-2fa.html`
   - User enters 6-digit code from authenticator app
   - User is authenticated and redirected to dashboard
3. If 2FA is not enabled:
   - User can access dashboard but will be prompted to set up 2FA when accessing assessments

### Accessing Assessments

1. User navigates to `/assessments/library/`
2. System checks if user has 2FA enabled
3. If not enabled:
   - User sees message: "2FA Required"
   - User is prompted to set up 2FA
   - Link to setup page is provided
4. If enabled:
   - User can browse and access assessments normally

## Dashboard Management

Users can manage 2FA from their dashboard:

1. Navigate to `/assessments/dashboard/`
2. View 2FA status in "Security Settings" section
3. Click "Setup 2FA" to enable (if not enabled)
4. Click "Disable 2FA" to disable (with confirmation)

## Technical Implementation

### Files Modified/Created

1. **`static/assessments/shared/auth-manager.js`**
   - Added `setup2FA()` - Generate TOTP secret and QR code
   - Added `verify2FASetup()` - Verify code during setup
   - Added `challenge2FA()` - Challenge 2FA after password login
   - Added `verify2FALogin()` - Verify code during login
   - Added `check2FAStatus()` - Check if user has 2FA enabled
   - Added `disable2FA()` - Disable 2FA for user
   - Added `require2FA()` - Check if 2FA is required and enabled
   - Modified `signInWithPassword()` - Handle 2FA challenge flow

2. **`static/assessments/auth/login.html`**
   - Updated to use `signInWithPassword()` method
   - Redirects to 2FA verification if 2FA is enabled
   - Shows note about 2FA requirement

3. **`static/assessments/auth/verify-2fa.html`** (NEW)
   - 2FA verification page for login flow
   - Accepts 6-digit code from authenticator app
   - Verifies code and completes authentication

4. **`static/assessments/auth/setup-2fa.html`** (NEW)
   - 2FA setup page for new users
   - Shows QR code and secret key
   - Two-step process: scan QR, then verify code
   - Handles required flag from registration flow

5. **`static/assessments/dashboard/index.html`**
   - Added "Security Settings" section
   - Shows 2FA status (Enabled/Not Enabled)
   - Provides buttons to setup or disable 2FA

6. **`static/assessments/library/index.html`**
   - Added 2FA requirement check before loading assessments
   - Redirects to setup page if 2FA not enabled

7. **`static/assessments/auth/register.html`**
   - Updated to redirect to 2FA setup after registration
   - Passes `required=true` flag to setup page

## Testing

### Test 2FA Setup

1. Create a new account
2. Should be redirected to 2FA setup page
3. Scan QR code with authenticator app
4. Enter 6-digit code to verify
5. Should be redirected to dashboard
6. Check dashboard - 2FA status should show "Enabled"

### Test 2FA Login

1. Sign out
2. Sign in with email and password
3. Should be redirected to 2FA verification page
4. Enter 6-digit code from authenticator app
5. Should be authenticated and redirected to dashboard

### Test 2FA Requirement

1. As a user without 2FA, try to access `/assessments/library/`
2. Should see "2FA Required" message
3. Click "Setup 2FA Now"
4. Complete setup
5. Should now be able to access assessments

### Test Disable 2FA

1. Go to dashboard
2. Click "Disable 2FA"
3. Confirm action
4. 2FA should be disabled
5. Try to access assessments - should be prompted to set up 2FA again

## Troubleshooting

### QR Code Not Generating

- Check that QRCode.js library is loaded (CDN link in setup-2fa.html)
- Check browser console for errors
- User can manually enter secret key if QR code fails

### 2FA Verification Fails

- Ensure code is entered within time window (usually 30 seconds)
- Check that authenticator app time is synchronized
- Verify secret key was entered correctly if manual entry was used

### User Can't Access Assessments

- Check that 2FA is enabled in Supabase dashboard
- Verify user has completed 2FA setup
- Check browser console for errors
- Ensure Supabase MFA is enabled in project settings

## Security Notes

- 2FA uses TOTP (Time-based One-Time Password) standard
- Secret keys are generated by Supabase and never stored in plain text
- QR codes are generated client-side and not sent to server
- 2FA verification happens server-side through Supabase Auth
- Users can disable 2FA, but will be prompted to re-enable when accessing protected features

