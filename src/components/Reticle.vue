<template>
    <div class="reticle" ref="reticle">
        <canvas
            class="reticle-canvas"
            ref="reticleCanvas"
            width="200"
            height="140"
            >
        </canvas>
        <img class="visor"
            ref="visor"
            :src=visor>
    </div>
</template>
<script>
import Utils from '/src/Utils.js'

let r = 100;

const CONTROLLER_DEADZONE = 0.15;
const MOVEMENT_SPEED = 5;

const HOTSPOT_RADIUS = 4;

const MAGNET_RADIUS = 30;
const MAGNET_SPEED = 2;

const hotspots = [
    { id: 'idle', x: 0, y: 0 },
    { id: 'A1', x: 896, y: 738 },
    { id: 'A2', x: 895, y: 405 },
    { id: 'A3', x: 1167, y: 589 },
    { id: 'A4', x: 840, y: 463 }
]

export default {
    props: [
        'image',
        'visor',
        'hotspot',
    ],
    emits: [
        'hotspotFound',
    ],
    data () {
        return {
            ctx: 0,
            im: null,
            controller: null,
            pos: {
                x: 0,
                y: 0,
            },
            posX: 0,
            posY: 0,
            rX: 100,
            rY: 70,
        };
    },
    methods: {
        redraw() {
            // Draw image section for full size map
            this.ctx.drawImage(this.im, this.pos.x-this.rX+4, this.pos.y-this.rY+4,
                2*this.rX, 2*this.rY,
                0, 0,
                2*this.rX, 2*this.rY);

            // Move to position
            this.$refs.reticle.style.left = this.pos.x - this.rX + "px"
            this.$refs.reticle.style.top = this.pos.y - this.rY + "px"
        },
        processControllerInput() {
            
            // TODO: replace polling with listeners
            if (!this.controller) {
                this.controller = navigator.getGamepads()[0];

            } else {

                // WARNING: this code does not work on chromium (input polling required), only firefox is tested
                if (!isNaN(this.controller.axes[0]) && Math.abs(this.controller.axes[0]) > CONTROLLER_DEADZONE) {
                    this.pos.x += this.controller.axes[0] * MOVEMENT_SPEED;
                }

                if (!isNaN(this.controller.axes[1]) && Math.abs(this.controller.axes[1]) > CONTROLLER_DEADZONE) {
                    this.pos.y += this.controller.axes[1] * MOVEMENT_SPEED;
                }
            }
        },
        processMouseInput(e) {
            this.pos.x = e.x;
            this.pos.y = e.y;
        },
        checkHotspots() {

            for (const spot of hotspots) {
                const d = this.distance(this.pos, spot);
                if (d < MAGNET_RADIUS && d > 1) {
                    
                    const dx = spot.x - this.pos.x;
                    // Prevent overshooting
                    if (Math.abs(dx) < MAGNET_SPEED) {
                        this.pos.x += dx;
                    } else {
                        this.pos.x += MAGNET_SPEED * Math.sign(dx);
                    }

                    const dy = spot.y - this.pos.y;
                    // Prevent overshooting
                    if (Math.abs(dy) < MAGNET_SPEED) {
                        this.pos.y += dy;
                    } else {
                        this.pos.y += MAGNET_SPEED * Math.sign(dy);
                    }
                }

                if (d < HOTSPOT_RADIUS) {
                    
                    // Prevent continuously reporting the same spot
                    if (this.hotspot !== spot.id) {
                        this.$emit('hotspotFound', spot.id);
                        Utils.triggerAnim(this.$refs.reticle, "flash", 1);
                    }
                }
            }
        },
        updateLoop() {
            window.requestAnimationFrame(loop)
            // WARNING: TODO:FIX: FRAMERATE-DEPENDENT

            this.processControllerInput();
            if (this.$refs.reticle) {
                this.redraw();
            }
            this.checkHotspots();
        },
        distance(a, b) {
            return Math.sqrt((a.x-b.x)**2 + (a.y-b.y)**2);
        }
    },
    mounted() {
        this.ctx = this.$refs.reticleCanvas.getContext("2d")
        this.im = new Image();
        this.im.src = this.$props.image;

        this.controller = navigator.getGamepads()[0];
        document.addEventListener("mousemove", this.processMouseInput)

        // Start interaction loop
        window.loop = this.updateLoop;
        loop();
    },

}
</script>
<style scoped>
.reticle {
    position: fixed;
    display: block;

    /* border:1px black solid;
    box-shadow: 5px 5px 10px #1e1e1e;
    border-radius: 20px; */
    border-radius: 16px;
}

.reticle-canvas {
    display: block;
    border-radius: inherit;
    padding: 4px;
}

.visor {
    position: absolute;
    top: 0;
    width: 100%;
    height: 100%;
}

.anim-flash {
    animation: flash 0.15s linear 0s 1 alternate;
}

@keyframes flash {
    33% { transform: scale(1.1); }
    83% { transform: scale(0.95); }
}
</style>