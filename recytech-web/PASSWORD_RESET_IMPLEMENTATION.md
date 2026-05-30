# Password Reset with PIN Implementation

## 📋 Overview

A complete password reset flow has been implemented with the following features:
- Email-based PIN verification (6-digit code)
- 15-minute PIN expiration
- Secure password reset with token validation
- Real-time countdown timer
- User-friendly UI with feedback

## 🏗️ Architecture

### Database Schema (User Model)
```javascript
resetPin: String           // 6-digit PIN (temporary)
resetPinExpiry: Date      // PIN expiration time
```

### API Endpoints

#### 1. **POST /api/auth/forgot-password**
Request password reset and send PIN via email.

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response (Success):**
```json
{
  "message": "Password reset PIN has been sent to your email. Valid for 15 minutes.",
  "email": "user@example.com"
}
```

**Features:**
- Generates 6-digit PIN
- Sets 15-minute expiry
- Sends PIN to email
- Doesn't reveal if email exists (security)

---

#### 2. **POST /api/auth/verify-pin**
Verify the PIN sent via email and get reset token.

**Request:**
```json
{
  "email": "user@example.com",
  "pin": "123456"
}
```

**Response (Success):**
```json
{
  "message": "PIN verified successfully",
  "resetToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "email": "user@example.com"
}
```

**Validations:**
- PIN must be exactly 6 digits
- PIN must match what was sent
- PIN must not be expired

---

#### 3. **POST /api/auth/reset-password**
Reset password using verified token.

**Request:**
```json
{
  "email": "user@example.com",
  "newPassword": "NewSecurePassword123!",
  "confirmPassword": "NewSecurePassword123!",
  "resetToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (Success):**
```json
{
  "message": "Password has been reset successfully. You can now login with your new password."
}
```

**Validations:**
- Password minimum 6 characters
- Passwords must match
- Reset token must be valid and not expired
- Clears PIN and expiry from database

---

## 🎨 Frontend Flow

### Page 1: ForgotPassword.jsx
- User enters email
- Calls `POST /api/auth/forgot-password`
- Redirects to PIN verification page

### Page 2: ResetPinVerification.jsx
- Displays 15-minute countdown timer
- User enters 6-digit PIN
- Calls `POST /api/auth/verify-pin`
- On success, redirects to password reset page

### Page 3: ResetPassword.jsx
- User enters new password
- Password visibility toggle
- Password requirements display
- Calls `POST /api/auth/reset-password`
- Redirects to login on success

---

## 🔧 Setup Instructions

### 1. Install Dependencies
```bash
cd recytech-prototype
npm install
```

### 2. Configure Email Service

#### Option A: Gmail (Recommended for testing)
1. Go to https://myaccount.google.com/apppasswords
2. Generate an app-specific password
3. Add to `.env`:
```
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-specific-password
```

#### Option B: Other Email Services
Edit `recytechbackend/routes/authRoutes.js` - Update the `transporter` configuration:

**For Outlook:**
```javascript
const transporter = nodemailer.createTransport({
    service: 'outlook',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD
    }
});
```

**For SendGrid:**
```javascript
const transporter = nodemailer.createTransport({
    host: 'smtp.sendgrid.net',
    port: 587,
    auth: {
        user: 'apikey',
        pass: process.env.EMAIL_PASSWORD
    }
});
```

### 3. Environment Variables
Create or update `.env` file:
```
MONGODB_URI=mongodb+srv://...
JWT_SECRET=your-secret-key
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
```

### 4. Start the Application
```bash
# Terminal 1: Backend
cd recytech-prototype
npm run dev

# Terminal 2: Frontend
cd recytech-prototype/recytechfrontend
npm run dev
```

---

## 🧪 Testing the Feature

### Manual Test Flow:
1. Navigate to http://localhost:5173/login
2. Click "Forgot Password?"
3. Enter a registered email address
4. Check email inbox for PIN (or spam folder)
5. Enter 6-digit PIN (expires in 15 minutes)
6. Enter new password
7. Login with new password

### Test Credentials (assuming existing users):
```
Email: admin@recytech.com
Old Password: password123
New Password: NewPassword456!
```

---

## 🔐 Security Features

✅ **PIN-based verification** - More secure than token in email
✅ **Time-based expiry** - PINs valid for 15 minutes only
✅ **One-time use** - PINs cleared after reset
✅ **JWT token validation** - Reset token valid for 1 hour
✅ **Password hashing** - bcrypt with 10 salt rounds
✅ **Email masking** - Doesn't reveal if email exists (brute force prevention)
✅ **Rate limiting** - Consider adding in production
✅ **HTTPS only** - Recommended for production

---

## ⚠️ Production Checklist

- [ ] Add rate limiting to `/auth/forgot-password` endpoint
- [ ] Use environment-specific email templates
- [ ] Enable HTTPS only for password reset pages
- [ ] Add logging for failed password reset attempts
- [ ] Consider adding CAPTCHA to forgot password form
- [ ] Test email delivery in production email service
- [ ] Monitor email bounces and failed deliveries
- [ ] Add metrics for password reset success/failure rates

---

## 📁 Files Created/Modified

**New Files:**
- `recytechfrontend/src/pages/ResetPinVerification.jsx`
- `recytechfrontend/src/pages/ResetPassword.jsx`
- `.env.example`

**Modified Files:**
- `recytechbackend/models/User.js` - Added resetPin, resetPinExpiry fields
- `recytechbackend/routes/authRoutes.js` - Added 3 password reset endpoints
- `recytechfrontend/src/pages/ForgotPassword.jsx` - Redirect to PIN verification
- `recytechfrontend/src/App.jsx` - Added 2 new routes
- `package.json` - Added nodemailer dependency

---

## 🐛 Troubleshooting

### Email not being sent
- Check EMAIL_USER and EMAIL_PASSWORD in .env
- For Gmail, verify App Password is correct (not regular password)
- Check spam/junk folder
- Enable "Less secure apps" if using Gmail account password

### PIN validation failing
- Ensure PIN is exactly 6 digits
- Check if PIN has expired (15-minute window)
- Verify email matches registered account

### Token expired error
- Reset token valid for 1 hour
- User must complete reset within 1 hour
- Request new PIN if needed

---

## 📞 Support

For issues or enhancements:
1. Check environment variables are correctly set
2. Verify email service credentials
3. Review console logs in backend terminal
4. Check MongoDB connection

---

## ✨ Future Enhancements

- [ ] SMS-based PIN alternative
- [ ] Biometric password reset
- [ ] Admin password reset for users
- [ ] Password reset history
- [ ] Customizable email templates
- [ ] Multi-language email templates
- [ ] Password strength meter
- [ ] Security questions backup
