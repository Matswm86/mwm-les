class_name DisengageDetector
extends RefCounted
## Random-tapping detector (GDD 5.5): RANDOM_TAP_COUNT wrong taps inside
## RANDOM_TAP_WINDOW_SEC = disengaged. Time is passed in so tests can replay it.

var _times: Array[float] = []


func wrong_tap(now_sec: float) -> bool:
	_times.append(now_sec)
	while not _times.is_empty() and now_sec - _times[0] > LearnBalance.RANDOM_TAP_WINDOW_SEC:
		_times.pop_front()
	if _times.size() >= LearnBalance.RANDOM_TAP_COUNT:
		_times.clear()
		return true
	return false


func reset() -> void:
	_times.clear()
