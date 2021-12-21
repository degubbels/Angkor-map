<template>
    <div :class="idle ? 'reticle r-idle' : 'reticle'" ref="reticle">
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

const IDLE_TIME = 8000;

const hotspots = [
    { id: 'idle', x: 0, y: 0 , type: 'none' },
    { id: 'A1', x: 896, y: 738, type: 'satellite' },
    { id: 'A2', x: 895, y: 405, type: 'satellite' },
    { id: 'A3', x: 1167, y: 589, type: 'satellite' },
    { id: 'A4', x: 840, y: 463, type: 'satellite' },
    { id: 'A5', x: 1298, y: 541, type: 'satellite' },
    { id: 'A6', x: 944, y: 324, type: 'satellite' },
    { id: 'A7', x: 984, y: 471, type: 'satellite' },
    { id: 'A8', x: 1239, y: 587, type: 'satellite' },
    { id: 'L1', x: 298, y: 561, type: 'lidar' },
    { id: 'L2', x: 898, y: 553, type: 'lidar' },
    { id: 'L3', x: 1570, y: 377, type: 'lidar' },
    { id: 'L4', x: 817, y: 758, type: 'lidar' },
    { id: 'L5', x: 1160, y: 304, type: 'lidar' },
    { id: 'L6', x: 799, y: 483, type: 'lidar' },
    { id: 'L7', x: 928, y: 888, type: 'lidar' },
    { id: 'L8', x: 1099, y: 760, type: 'lidar' }
]

export default {
    props: [
        'image',
        'lidarImage',
        'visor',
        'hotspot',
        'idle',
    ],
    emits: [
        'hotspotFound',
        'enter-idle',
        'leave-idle'
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
            lastpos: {
                x: 0,
                y: 0,
            },
            rX: 100,
            rY: 70,
            lastTimestamp: 0,
            lastMovement: 0,
        };
    },
    methods: {
        redraw() {
            // Check bounds
            if (this.pos.x < 0) { this.pos.x = 0 }
            if (this.pos.x > 1920) { this.pos.x = 1920 }
            if (this.pos.y < 0) { this.pos.y = 0 }
            if (this.pos.y > 1200) { this.pos.y = 1200 }

            // Draw image section for full size map
            this.ctx.drawImage(this.im, this.pos.x-this.rX, this.pos.y-this.rY,
                2*this.rX, 2*this.rY,
                0, 0,
                2*this.rX, 2*this.rY);
            
            // Move to position
            this.$refs.reticle.style.left = this.pos.x - this.rX - 4 + "px";
            this.$refs.reticle.style.top = this.pos.y - this.rY - 4 + "px";
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
                    if (this.hotspot !== spot.id && (this.pos.x != this.lastpos.x || this.pos.y != this.lastpos.y)) {
                        this.hotspotTrigger(spot)
                    }
                }
            }
        },
        hotspotTrigger(spot) {
            this.$emit('hotspotFound', spot.id);
            Utils.triggerAnim(this.$refs.reticle, "flash", 1);
            if (spot.type === 'lidar') {
                this.im = this.imLidar;
            } else {
                this.im = this.imSat;
            }
        },
        updateLoop(timestamp) {
            window.requestAnimationFrame(this.updateLoop);
            // WARNING: TODO:FIX: FRAMERATE-DEPENDENT
            const delta = timestamp - this.lastTimestamp

            // Track idle timer
            if (this.pos.x != this.lastpos.x || this.pos.y != this.lastpos.y) {
                this.lastMovement = timestamp;

                if (this.idle) {
                    this.$emit('leave-idle');
                    // this.idle = false;
                }
            }
            this.lastpos.x = this.pos.x;
            this.lastpos.y = this.pos.y;

            if (timestamp - this.lastMovement > IDLE_TIME && !this.idle) {
                this.$emit('enter-idle');
                // this.idle = true;
            }

            this.processControllerInput();
            if (this.$refs.reticle) {
                this.redraw();
            }
            this.checkHotspots();

            this.lastTimestamp = timestamp;
        },
        distance(a, b) {
            return Math.sqrt((a.x-b.x)**2 + (a.y-b.y)**2);
        }
    },
    mounted() {
        this.ctx = this.$refs.reticleCanvas.getContext("2d")

        // Prepare images for both satellite and lidar
        this.imSat = new Image();
        this.imSat.src = this.$props.image;
        this.imLidar = new Image();
        this.imLidar.src = this.$props.lidarImage;
        this.im = this.imSat;

        this.controller = navigator.getGamepads()[0];
        document.addEventListener("mousemove", this.processMouseInput)

        // Start interaction loop
        window.requestAnimationFrame(this.updateLoop);
    },

}
</script>
<style scoped>
.reticle {
    position: fixed;
    display: block;
    z-index: 10;

    /* border:1px black solid;
    box-shadow: 5px 5px 10px #1e1e1e;
    border-radius: 20px; */
    border-radius: 16px;
}

.r-idle {
    z-index: 8;
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