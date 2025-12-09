# 🎯 ACTION: Fix Supabase Email Settings NOW

## ⏱️ This Takes 5 Minutes

### Step 1: Open Supabase Dashboard
```
URL: https://supabase.com/dashboard
```

### Step 2: Go to Email Provider Settings
```
Left Menu:
  Authentication → Providers

Click on Email card
```

### Step 3: Find Email Confirmations Setting

Scroll down and look for a **DROPDOWN** that says:

```
Email Confirmations
  └─ Current value: "Always require" or "Require email"
```

### Step 4: Click the Dropdown

Click on it and select: **"Disabled"**

### Step 5: Find Autoconfirm Users Setting

Look for a **TOGGLE** that says:

```
Autoconfirm users
  └─ Current value: OFF
```

### Step 6: Turn ON the Toggle

Click it to turn: **ON**

### Step 7: Save Changes

Find the green button (usually top right):
```
[Save changes]
```

Click it!

### Step 8: Done! 🎉

Wait 10 seconds for changes to apply.

---

## ✅ Verify Changes

Go back to Email Provider settings and verify:

```
✅ Email Confirmations: Disabled (not "Always require")
✅ Autoconfirm users: ON (toggle is green)
✅ Save changes: Success message appeared
```

---

## 🚀 Next: Test the App

After changes are applied:

1. Close Flutter app
2. Run: `flutter clean && flutter pub get && flutter build apk --release`
3. Test registration with `test@example.com`
4. Expected: ✅ Registration succeeds

---

## 📸 Screenshots You Should See

### Before (WRONG):
```
Email Confirmations: "Always require"  ❌
Autoconfirm users: OFF  ❌
```

### After (CORRECT):
```
Email Confirmations: "Disabled"  ✅
Autoconfirm users: ON  ✅
```

---

## 💬 Need Help Finding The Settings?

If you can't find these settings:
1. Go to Supabase Dashboard
2. Click your project name
3. Left sidebar: Look for **Authentication**
4. In Authentication, look for **Providers**
5. Click on **Email** card
6. Settings form opens below

---

## ⏸️ Go Do This Now!

**Don't continue until you:**
- [ ] Changed Email Confirmations to "Disabled"
- [ ] Turned ON Autoconfirm users
- [ ] Clicked Save changes
- [ ] Saw success message

Then come back here!
