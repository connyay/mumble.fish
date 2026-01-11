# macOS App Signing & Notarization

This document explains how to configure the GitHub Actions secrets required for signing and notarizing the MumbleFish macOS app.

## Overview

The build workflow supports three modes:

1. **Unsigned build** - No secrets required. Produces an unsigned `.dmg` that will show security warnings when opened.
2. **Signed build** - Requires certificate secrets. Produces a signed app that macOS will trust.
3. **Signed + Notarized build** - Requires all secrets. Produces a fully notarized app that passes Gatekeeper without warnings.

## Required Secrets

### For Code Signing

#### `APPLE_CERTIFICATE_BASE64`

Base64-encoded Developer ID Application certificate (.p12 file).

**How to obtain:**

1. Open **Keychain Access** on your Mac
2. In the login keychain, find your "Developer ID Application: Your Name (TEAM_ID)" certificate
3. Right-click and select **Export**
4. Save as a `.p12` file with a strong password
5. Convert to base64:

   ```bash
   base64 -i certificate.p12 | pbcopy
   ```

6. Paste the result as the secret value

#### `APPLE_CERTIFICATE_PASSWORD`

The password you set when exporting the .p12 certificate.

#### `APPLE_TEAM_ID`

Your Apple Developer Team ID.

**How to find:**

1. Go to [Apple Developer Account](https://developer.apple.com/account)
2. Look in the top-right corner or under **Membership Details**
3. It's a 10-character alphanumeric string (e.g., `ABC123DEF4`)

### For Notarization

#### `APPLE_ID`

The email address associated with your Apple Developer account.

#### `APPLE_APP_SPECIFIC_PASSWORD`

An app-specific password for your Apple ID (required for notarization).

**How to create:**

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in and go to **Sign-In and Security** > **App-Specific Passwords**
3. Click **Generate an app-specific password**
4. Name it something like "GitHub Actions Notarization"
5. Copy the generated password (format: `xxxx-xxxx-xxxx-xxxx`)

## Adding Secrets to GitHub

1. Go to your repository on GitHub
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret** for each secret:

| Secret Name                   | Description                     |
| ----------------------------- | ------------------------------- |
| `APPLE_CERTIFICATE_BASE64`    | Base64-encoded .p12 certificate |
| `APPLE_CERTIFICATE_PASSWORD`  | Password for the .p12 file      |
| `APPLE_TEAM_ID`               | Your 10-character Team ID       |
| `APPLE_ID`                    | Your Apple Developer email      |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password           |

## Prerequisites

Before you can sign and notarize:

1. **Apple Developer Program membership** ($99/year) - Required for Developer ID certificates
2. **Developer ID Application certificate** - Create at [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates)
   - Select "Developer ID Application" when creating
   - This allows distributing apps outside the Mac App Store

## Triggering Builds

The workflow runs:

- Automatically when you push a tag starting with `v` (e.g., `v1.0.0`)
- Manually via **Actions** > **Build macOS App** > **Run workflow**

## Troubleshooting

### "The certificate has an invalid issuer"

Your certificate may have expired or wasn't properly exported. Re-export from Keychain Access.

### "Unable to notarize"

- Verify your Apple ID and app-specific password are correct
- Ensure your Apple Developer account is in good standing
- Check that the Team ID matches the certificate

### Build works but app shows "unidentified developer"

The certificate secrets are missing or invalid. Check the workflow logs to see if signing was skipped.
