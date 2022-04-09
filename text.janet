(use freja/flow)
(import freja/assets)

(def dark 0x2a2e2dff)
(def dark-blue 0x0e9aa7ff)
(def light-blue 0x3da4abff)
(def yellow 0xf6cd61ff)
(def red 0xfe8a71ff)

(def standard-color [0.9 0.9 0.9])
(def regular-speed [0.05 0.08])
(def fast [0.004 0.0045])

(var mp nil)
(var last-text nil)
(var last-overlay nil)
(var text nil)
(var removed-chars nil)
(var text-speed nil)
(var text-color nil)
(var timer nil)
(var delay nil)
(var text-size nil)
(var choice-size nil)
(var overlay nil)
(def r-size [800 600])
(var stack nil)
(var bg nil)


(defn center
  []
  (rl-translatef (math/floor (* 0.5 (r-size 0)))
                 (math/floor (* 0.5 (r-size 1)))
                 0))

(defn -to0
  [v1 v2]
  (max (- v1 v2) 0))

(defn clamp
  [mi ma v]
  (max (min v ma) mi))

(defn fill
  [color]
  (draw-rectangle
    ;(map math/floor (v/v* r-size -0.5))
    ;r-size
    color))

(var game-state @{})

(defn game-over
  [state]
  (def start-time 1)
  (put state :timer start-time)
  (fn game-over-inner []
    (update state :timer - (get-frame-time))
    (fill
      [0 0 0
       (clamp
         0 1
         (/ (- start-time (state :timer))
            start-time))])
    (when (< (state :timer) -1)
      (set stack @[["you win"]]))))

(defn reset-stack
  [newstack]
  (set text nil)
  (set stack @[;(if (function? newstack)
                  (newstack)
                  newstack)]))

(defn red-overlay
  [state]
  (def start-time 1)
  (put state :timer start-time)
  (fn []
    (update state :timer - (get-frame-time))
    (fill
      [1
       0
       0
       (math/sin
         (* math/pi
            (clamp
              0 1
              (/ (- start-time (state :timer))
                 start-time))))])))

(defn flash-overlay
  [color]
  (def state @{})
  (def start-time 1)
  (put state :timer start-time)
  (fn []
    (update state :timer - (get-frame-time))
    (fill
      [;color
       (math/sin
         (* math/pi
            (clamp
              0 1
              (/ (- start-time (state :timer))
                 start-time))))])))

(varfn start-stack [])

(def dead-stack
  [["you die"]])

(defn hit-head-stack
  [after]
  [|(do (set overlay (red-overlay @{}))
      (set text-speed fast))
   ["head meets metal"]
   |(do (set text-speed regular-speed)
      (update game-state :hp dec)
      (set overlay nil))
   |(if (pos? (game-state :hp))
      (reset-stack after)
      (reset-stack dead-stack))])

(def exit-stack
  [|(set overlay (flash-overlay [1 1 1]))
   |(set delay 0.5)
   |(set bg light-blue)
   |(set delay 0.6)
   |(set text-color dark)
   |(set overlay nil)
   ["empty space"]
   |(set text-color standard-color)])

(def gate-ahead
  [["exit..."]
   ["exit"]
   ["an exit!?"]
   ["finally - a door"
    [["look" [["it says PULL"
               [["pull" exit-stack]
                ["push" [["really?"]
                         |(reset-stack
                            (hit-head-stack
                              [["door says PULL"
                                [["pull" exit-stack]
                                 ["push" [["nice move"]
                                          |(reset-stack
                                             (hit-head-stack
                                               [["ouch"]
                                                |(reset-stack
                                                   (hit-head-stack
                                                     [["urgh"]]))]))]]]]]))]]]]]]
     ["push push push"
      (hit-head-stack [["door says PULL"
                        [["pull" exit-stack]
                         ["push" [["are you blind... I mean-"]
                                  |(reset-stack
                                     (hit-head-stack
                                       [["better luck next time"
                                         [["pull" exit-stack]
                                          ["push" [["madam"]
                                                   |(reset-stack
                                                      (hit-head-stack
                                                        [["ouch"]
                                                         |(reset-stack
                                                            (hit-head-stack
                                                              [["urgh"]]))]))]]]]]))]]]]])]]]])

(def right-stack
  [["metal creaking behind you"
    [["don't look" gate-ahead]
     ["look back" (hit-head-stack [["crap"
                                    [["gotta run" gate-ahead]]]])]]]])

#(def cur-test-stack gate-ahead)

(def push-stack
  [["knight in hallway"
    [["right" right-stack]]]])

(var door-stack nil)
(set door-stack
     [["wooden door metal handle"]
      ["sign says PUSH"
       [["push" push-stack]
        ["pull" [["the door will not budge"]
                 |(reset-stack door-stack)]]]]])

(def light-on-stack
  [["*click*"]
   |(set overlay (flash-overlay [1 1 1]))
   |(set delay 0.5)
   |(set bg [0.3 0.3 0.3])
   |(set delay 0.6)
   |(put game-state :light true)
   |(set overlay nil)
   |(reset-stack door-stack)])

(var dark-door-stack nil)
(set dark-door-stack
     [["on your feet"
       [["light?" light-on-stack]
        ["pull" [["*creak*"]
                 ["nothing"]
                 |(reset-stack dark-door-stack)]]]]])

(var search-stack nil)
(set search-stack
     [["wood ahead"
       [["inspect" [["you find a handle"
                     [["stand" |(do (put game-state :crawl false)
                                  (reset-stack dark-door-stack))]
                      ["pull" [["*creak*"]
                               ["nothing"]
                               |(reset-stack search-stack)]]]]]]
        ["kick" [["nothing"]
                 |(reset-stack search-stack)]]]]])

(def crawl-stack
  [["cold marble meet your hands"]
   |(reset-stack start-stack)])

(varfn start-stack
  []
  [["the room is dark"
    [["search" |(if (game-state :crawl)
                  (reset-stack search-stack)
                  (reset-stack (hit-head-stack start-stack)))]
     (if (game-state :crawl)
       ["stand" [["welp"]]]
       ["crawl" |(do (put game-state :crawl true)
                   (reset-stack crawl-stack))])]]])

(var inited-fonts (dyn :freja/loading-file))

(defn restart
  []
  (set-exit-key :f11)

  (unless inited-fonts
    (assets/register-font "EBGaramond"
                          :style :regular
                          :path "EBGaramond12-Regular.otf")
    (set inited-fonts true))

  (set game-state @{:hp 2})
  (set mp @[0 0])
  (set text-color standard-color)
  (set bg dark)
  (set choice-size 30)
  (set overlay nil)
  (set removed-chars nil)
  (set text nil)
  (set last-overlay nil)
  (set last-text nil)
  (set text-size 38)
  #(set r-size @[0 0])
  (set text-speed regular-speed)
  (set timer (text-speed 0))
  (set delay 0)

  (reset-stack start-stack
               #cur-test-stack
))

(defn menu-overlay
  []
  (fill [0.1 0.1 0.1]))

(defn menu
  []
  (set text ["press r to restart, or escape to continue"])
  (set removed-chars (length (text 0))))

(defn next-character
  []
  (unless (pos? delay)
    (if text
      (-- removed-chars)
      (when-let [t (get stack 0)]
        (if (function? t)
          (do
            (array/remove stack 0)
            (t))
          (do (array/remove stack 0)
            (set text t)
            (set removed-chars (length (first t)))))))))

(defn lerp
  [start stop t]
  (+ start (* t (- stop start))))

(defn rng
  [start stop]
  (lerp start stop (math/random)))

(defn left-choice?
  []
  (and
    (> (mp 1) (+ 50 (* 0.5 (r-size 1))))
    (< (mp 0) (* 0.5 (r-size 0)))))

(defn right-choice?
  []
  (and
    (> (mp 1) (+ 50 (* 0.5 (r-size 1))))
    (> (mp 0) (* 0.5 (r-size 0)))))

(defn render-choice
  [[[choice _] c2]]

  (when (<= removed-chars 0)
    (let [t (string "> " (string/slice choice 0 (min (length choice)
                                                     (- removed-chars))))
          [w h] (measure-text t :size choice-size)
          offset 100
          near (left-choice?)]
      (defer (rl-pop-matrix)
        (rl-push-matrix)
        (rl-translatef (- (- w) offset) 0 0)
        (draw-text t
                   [0 100]
                   :size choice-size
                   :color (if near
                            :white
                            [0.8 0.8 0.8]))))

    (when-let [[choice2 _] c2]
      (let [t (string "> " (string/slice choice2 0 (min (length choice2)
                                                        (- removed-chars))))
            [w h] (measure-text t :size choice-size)
            offset 100
            near (right-choice?)]
        (defer (rl-pop-matrix)
          (rl-push-matrix)
          (rl-translatef (+ offset) 0 0)
          (draw-text t
                     [0 100]
                     :size choice-size
                     :color (if near
                              :white
                              [0.8 0.8 0.8])))))))

(defn render
  [{:width rw :height rh}]
  #(set r-size [rw rh])
  (-= timer (get-frame-time))
  (-= delay (get-frame-time))
  (while (<= timer 0)
    (next-character)
    (set timer (+ (rng ;text-speed)
                  timer)))
  (clear-background bg)

  (center)

  (when overlay
    (overlay))

  (when (and (empty? stack)
             (nil? text)
             (nil? overlay))
    (print "game over")
    (set overlay (game-over @{})))

  (when-let [[text choice] text]
    (draw-text (string/slice text 0 (- (max 1 removed-chars)))
               [0 0]
               :size text-size
               :color text-color
               :center true)
    (when choice
      (render-choice choice))))

(defn choose
  [choice]
  (if (function? choice)
    (choice)
    (reset-stack choice)))

(defn on-event
  [_ ev]
  (match ev
    {:key/release :escape}
    (if (= overlay menu-overlay)
      (let [[tex rem speed] last-text]
        (set text tex)
        (set text-speed speed)
        (set removed-chars rem)
        (set last-text nil)
        (set overlay last-overlay)
        (set last-overlay nil))
      (do (set last-text [text removed-chars text-speed])
        (set text-speed [0.005 0.006])
        (set last-overlay overlay)
        (set overlay menu-overlay)
        (menu)))

    ({:key/down :r} (= overlay menu-overlay))
    (restart)

    {:mouse/down _}
    (unless (= overlay menu-overlay)
      (if (<= removed-chars 0)
        (when-let [[_ choice] text]
          (if choice
            (cond (left-choice?)
              (choose (get-in choice [0 1]))

              (and (right-choice?)
                   (choice 1))
              (choose (get-in choice [1 1])))

            (set text nil)))
        (set removed-chars 0)))

    {:mouse/pos p}
    (set mp p)))

(start-game {:init restart
             :render render
             :size r-size
             :on-event on-event})
