; Knobs for the cinder overlay. A settings panel can write this file later.
; Change a value, then refresh Cinders\Overlay from the Rainmeter tray icon.
[Variables]
; 0 hides every cinder. 1 shows them.
EmberOn=1

; 1 is a light drift (16), 2 adds a second set (32), 3 fills the screen (48).
EmberDensity=2

; 1 is a slow rise. 2 is twice as fast. 0.6 is barely moving.
EmberSpeed=3

; 0 rises straight up. 1 rises and drifts left and right, like a cinder in moving air.
EmberSway=1

; 1 is the drawn size. 0.7 is smaller, 1.6 is larger.
EmberScale=1

; Soft halo. The sprite is white, and this color multiplies it.
EmberTint=255,118,32

; Hot center, drawn smaller on top of the halo.
EmberCore=255,236,198

; Peak opacity of a cinder, from 0 to 255. Each sprite scales this a little.
EmberPeak=210

; Which displays show the rise. 1 is on, 0 is off. Any mix works, and all three on is every display at once.
; 1 is the primary screen. 2 and 3 are the other displays, in Rainmeter's order.
; Change these, then refresh Cinders\Overlay. That loads the displays that are on.
; After editing formulas in Overlay.ini, run @Resources\SyncMonitors.ps1, then refresh again.
Monitor1=1
Monitor2=1
Monitor3=0
