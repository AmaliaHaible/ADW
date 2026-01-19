import asyncio
from winrt.windows.media.control import \
    GlobalSystemMediaTransportControlsSessionManager as MediaManager



async def main():
    manager = await MediaManager.request_async()
    default_session = manager.get_current_session()
    sessions = manager.get_sessions()

    s = default_session
    x = s.get_playback_info()
    print(dir(x))
    for s in sessions:
        print(s)

        # Control playback
        # await s.try_toggle_play_pause_async()
        # await s.try_skip_next_async()
        # await s.try_skip_previous_async()
        # await s.try_stop_async()

asyncio.run(main())
