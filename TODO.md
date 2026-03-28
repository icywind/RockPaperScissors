# Refactor AgoraRtcViewModel to Singleton Controller

## Steps (planned):

1. ✅ [DONE] Create TODO.md with implementation plan
2. ✅ [DONE] Create new `RockPaperScissors/Controller/AgoraRtcController.swift` - move all RTC logic there as singleton with @Published properties and delegates
3. ✅ [DONE] Refactor `RockPaperScissors/ViewModel/AgoraRtcViewModel.swift` to proxy to controller (slim ViewModel with only publishing) - class renamed to AgoraViewModel for compatibility
4. ✅ [DONE] Move simulator extension to `RockPaperScissors/Controller/AgoraRtcController+Simulator.swift` + compilation fixes (typealias, channelName public, syntax)
5. ✅ [DONE] Update `RockPaperScissors/ViewModel/GameViewModel.swift` - calls compatible (no changes needed)
6. ✅ [DONE] Update `RockPaperScissors/View/BvsP1View.swift`, `RockPaperScissors/View/P1vsBView.swift` - replace onDestory → destroy
7. ✅ [DONE] Delete old AgoraViewModel+Simulator.swift
8. Verify no compilation errors (check dependent imports/types)
9. [USER TESTING] Manual test P2P modes (video, messages)
6. Update `RockPaperScissors/View/BvsP1View.swift` - change instantiation/calls to new AgoraRtcViewModel
7. Update `RockPaperScissors/View/P1vsBView.swift` - change instantiation/calls to new AgoraRtcViewModel
8. Verify no compilation errors (check dependent imports/types)
9. [USER TESTING] Manual test P2P modes (video, messages)

## Progress
- Current: Step 1 complete

**Next step:** Proceed to Step 2?

