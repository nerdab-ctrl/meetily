# iQOO Photo Rescue: one-page checklist

**Bottom line:** your photos can only come off this phone if the faulty board **boots Android one more time** and you enter your PIN. Recovery mode cannot reach them. Android encrypts the photos with keys inside this board's processor, and no tool (web, Mac or service-centre software) can read them from recovery mode or from a storage chip moved to another board. Every bootloop may use up one of the remaining boots, so **stop casual restarts now** and only power on when you're ready to copy.

---

## Never press these. They erase the photos permanently.
- **Wipe data / Clear all data / Factory reset / Format**: anything with *all data*, *factory*, *format* or *erase*. If a screen shows one of these words, go back.
- **Software flash / reinstall / "upgrade"** by anyone who can't guarantee it keeps your data.
- **"Clear cache"** is the only safe option. It doesn't touch photos.

---

## Step 1: set up the Mac BEFORE you power the phone on (≈10 min, once)
1. Install Homebrew if you don't have it (brew.sh), then in Terminal:
   ```bash
   brew install android-platform-tools      # gives you adb
   brew install --cask openmtp              # drag-and-drop file copier for Android
   ```
2. Use a **data** USB cable you know works. Test it with another phone; many cheap cables only charge.
3. Make sure the Mac has free space: about 1.5× your phone's used storage.
4. Download `grab-photos.sh` from this folder and make it runnable:
   ```bash
   chmod +x grab-photos.sh
   ```

## Step 2: the DIY boot attempt (at most 2–3 tries, then go to Step 3)
1. Leave the phone **powered off for 30+ min** to cool fully. Take off the case. Keep it on a cool, hard surface (not your lap or a pillow).
2. Boot menu → **Clear cache** (once only).
3. Choose a **normal reboot**, not safe mode.
4. **If it reaches the lock screen:**
   - Enter the PIN.
   - Plug into the Mac and choose **"File transfer"** on the USB prompt.
   - Choose **one** route below, depending on how stable the phone looks.

| Phone looks… | Do this |
|---|---|
| Unstable (lags, hot, likely to restart in < 2 min) | **Route A: OpenMTP right away.** Open OpenMTP and drag **DCIM → Camera** to the Mac first (newest month first if the folder is huge), then `Pictures`, then `Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images`. |
| Holds for a few minutes | **Route B: switch on USB debugging (≈40 s), then let the script run.** Settings → About phone → tap **Software version** 7 times. Then Settings → System management (or *Additional settings*) → Developer options → **USB debugging ON**. Tap **Allow** and tick **Always allow** when the phone asks. |

With **USB debugging on**, run this and leave it running:
```bash
./grab-photos.sh ~/Desktop/phone-photos
```
- It copies newest photos first, then WhatsApp images, then screenshots and other pictures, and **videos last** (they're big).
- If the phone crashes or bootloops, **leave the script running and the cable plugged in.** It resumes by itself every time the phone comes back up. Nothing is copied twice, and no half-copied file is ever kept.
- It ends with `DONE. All N files are safe…`.
- It only **reads** from the phone. It never deletes or changes anything there.

## Step 3: if it won't boot, go to a chip-level repair shop (not the authorised centre)
The authorised centre only swaps the whole board, which loses the data. Your symptoms fit a solder or power-chip fault under heat or load: recovery stays up, but Android, which works the chip harder, crashes, and it's getting worse. Independent **micro-soldering / board-level** shops often fix this for a fraction of the price of a new board. *(This is my reading of the symptoms; the technician has to confirm it.)*

**Ask before handing it over:**
- "Have you done **data recovery** on vivo/iQOO boards before?"
- "Will you **reflow/reball** the CPU or storage chip, or check the power IC?"
- "Do you promise **no factory reset and no software flashing**?"

**What to say (Hinglish):**
> *"Mujhe sirf photos chahiye. Phone permanently theek nahi bhi ho to chalega — bas ek baar on ho jaaye. Factory reset ya software flash bilkul nahi karna. On hote hi main khud copy kar lunga."*

- **Cost (estimate):** ₹2,000–8,000 in Pune. A new board costs about the price of a new phone. *(The range is an assumption: get 2 quotes.)*
- **Take with you:** the MacBook (with Step 1 done), the cable and your PIN. **Copy the photos at the shop** the moment it boots: Route A or B above.
- **Last resort:** some specialist labs move the CPU and storage chips together onto a donor board, which keeps the encryption keys with the data. It's costly and risky, and only worth it with a lab that has done it on your exact model.

---

## Quick reference: what each phone state means
| What you see | Can photos be copied? | What to do |
|---|---|---|
| Lock screen / home screen | **Yes** | Step 2, Route A or B |
| Recovery menu (stays up) | No, data is locked | Don't wipe anything; reboot normally or go to Step 3 |
| Logo → restarts in a loop | No | Stop after 2–3 tries; go to Step 3 |
| Safe mode → loops | No | Same as above |
