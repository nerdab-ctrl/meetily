# android-rescue

Recover photos from a failing (bootlooping) Android phone onto a Mac.

- **Start here:** [RESCUE_GUIDE.md](RESCUE_GUIDE.md), a one-page checklist covering what to press, what never to press, and when to go to a repair shop.
- **`grab-photos.sh`:** a resumable copier that grabs newest photos first and continues automatically after every crash or reboot. It needs `adb` (`brew install android-platform-tools`) and USB debugging on the phone. It only reads from the phone.

```bash
chmod +x grab-photos.sh
./grab-photos.sh ~/Desktop/phone-photos
```

Not part of the Meetily app. This is a standalone utility.
