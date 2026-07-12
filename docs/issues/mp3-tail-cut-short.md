# MP3 tail cut short before "Delay after audio"

**Status:** Fixed
**Area:** `lib/services/tts_speaker.dart` (`TtsSpeaker`)

## Symptom

After a km-completion announcement, the custom MP3 stopped ~1 second before the end
of the file. The configured "Delay after audio" (`delayAfterAudioMs`, e.g. 3000ms)
then ran as pure silence. Increasing the delay did **not** recover the missing tail —
it only lengthened the silent gap.

## Root cause

`_audioPlayer = AudioPlayer()` never set a `ReleaseMode`. audioplayers 6.x defaults
to **`ReleaseMode.release`**, which frees the native source **at completion**. So the
moment `onPlayerComplete` fired, the decoded tail still queued in the hardware buffer
was discarded — the ~1s cut.

The drain `Future.delayed(delayAfterAudioMs)` ran *after* that free, so it waited in
silence: the tail it was meant to protect was already gone.

Secondary hazard: a second listener on `onPlayerStateChanged` completed the wait on
`PlayerState.stopped` and jumped to the "non-natural" branch that called `stop()`
immediately — racing natural completion and cutting the tail with no drain at all.

## Fix

- `init()`: `await _audioPlayer!.setReleaseMode(ReleaseMode.stop);` — keep the source
  alive at completion so the buffered tail keeps draining.
- `_playMp3WithFocus()`: removed the `PlayerState.stopped` early-complete listener
  (it races natural completion). Wait only on `onPlayerComplete` (30s timeout
  backstop), run the drain delay while the player is still alive, then `stop()` to
  free it for the next playback.

## Verification

- On device, set "Delay after audio" to 3000ms, complete a km. MP3 plays to its full
  end (no ~1s cut), then the silent gap. Compare 0ms vs 3000ms — tail intact in both;
  only trailing silence changes.
- `adb logcat | findstr "MP3\|TTS\|flutter"` — `onPlayerComplete` fires, then drain
  log, then stop.

## If it regresses

If logcat shows `onPlayerComplete` firing well before the file's real length (early
completion — e.g. VBR MP3 with a bad/missing Xing header, so reported duration is
wrong), the buffer-drain approach can't help. Fallback: wait on `getDuration()`
instead of `onPlayerComplete`.
