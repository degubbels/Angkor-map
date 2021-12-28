<template>
    <div :class="idle ? 'reticle r-idle' : 'reticle'" ref="reticle">
        <div class="databus" v-show="false">
            <input class="posreceive-x" ref="posreceivex" value="0">
            <input class="posreceive-y" ref="posreceivey" value="0">
            <div @click="processIMInput" class="posreceive-pending" ref="posreceivepending" value=0>pen</div>
        </div>
        <canvas
            class="reticle-canvas"
            ref="reticleCanvasSat"
            :width="orientation === 'horizontal' ? 232 : 172"
            :height="orientation === 'horizontal' ? 172 : 232"
            >
        </canvas>
        <canvas
            class="reticle-canvas"
            ref="reticleCanvasLidar"
            :width="orientation === 'horizontal' ? 232 : 172"
            :height="orientation === 'horizontal' ? 172 : 232"
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
const MOVEMENT_SPEED = 3;

const HOTSPOT_RADIUS = 4;

const MAGNET_RADIUS = 10;
const MAGNET_SPEED = 6;

const IDLE_TIME = 8;

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
        'gamepad',
        'orientation'
    ],
    emits: [
        'hotspotFound',
        'enter-idle',
        'leave-idle'
    ],
    data () {
        return {
            ctxSat: 0,
            ctxLidar: 0,
            controller: null,
            pos: {
                x: 0,
                y: 0,
            },
            lastpos: {
                x: 0,
                y: 0,
            },
            rX: 116,
            rY: 86,
            lastTimestamp: 0,
            lastMovement: 0,
            currSpot: 'idle',
            imSat: null,
            imLidar: null,
            renderLayer: 'satellite',
            renderTimeout: null,
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
            if (this.renderLayer === 'satellite' || this.renderLayer === 'both') {
                this.ctxSat.drawImage(this.imSat, this.pos.x-this.rX, this.pos.y-this.rY,
                    2*this.rX, 2*this.rY,
                    0, 0,
                    2*this.rX, 2*this.rY);
            }

            if (this.renderLayer === 'lidar' || this.renderLayer === 'both') {
                this.ctxLidar.drawImage(this.imLidar, this.pos.x-this.rX, this.pos.y-this.rY,
                    2*this.rX, 2*this.rY,
                    0, 0,
                    2*this.rX, 2*this.rY);
            }
            
            // Move to position
            this.$refs.reticle.style.left = this.pos.x - this.rX - 4 + "px";
            this.$refs.reticle.style.top = this.pos.y - this.rY - 4 + "px";
        },
        processControllerInput(delta) {
            
            this.controller = navigator.getGamepads()[this.$props.gamepad];

            if (this.controller) {

                if (!isNaN(this.controller.axes[0]) && Math.abs(this.controller.axes[0]) > CONTROLLER_DEADZONE) {
                    this.pos.x += this.controller.axes[0] * MOVEMENT_SPEED * delta;
                }

                if (!isNaN(this.controller.axes[1]) && Math.abs(this.controller.axes[1]) > CONTROLLER_DEADZONE) {
                    this.pos.y += this.controller.axes[1] * MOVEMENT_SPEED * delta;
                }
            }
        },
        processIMInput(delta) {
            // if (this.$refs.posreceivepending.value === 'true') {
            this.pos.x += Math.sign(this.$refs.posreceivex.value) * MOVEMENT_SPEED;
            this.pos.y += Math.sign(this.$refs.posreceivey.value) * MOVEMENT_SPEED;
            console.log(this.$refs.posreceivepending.value);
            this.$refs.posreceivepending.value = 0;
            // }
        },
        processMouseInput(e) {
            this.pos.x = e.x;
            this.pos.y = e.y;
        },
        checkHotspots(delta) {

            for (const spot of hotspots) {
                const d = this.distance(this.pos, spot);
                if (d < MAGNET_RADIUS && d > 1) {
                    
                    const dx = spot.x - this.pos.x;
                    // Prevent overshooting
                    if (Math.abs(dx) < MAGNET_SPEED * delta) {
                        this.pos.x += dx;
                    } else {
                        this.pos.x += MAGNET_SPEED * Math.sign(dx) * delta;
                    }

                    const dy = spot.y - this.pos.y;
                    // Prevent overshooting
                    if (Math.abs(dy) < MAGNET_SPEED * delta) {
                        this.pos.y += dy;
                    } else {
                        this.pos.y += MAGNET_SPEED * Math.sign(dy) * delta;
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
            this.currSpot = spot.id;
            Utils.triggerAnim(this.$refs.reticle, "flash", 1);

            this.switchRenderLayer(spot.type);
        },
        onIdle() {
            this.currSpot = 'idle';
            this.redraw();

            this.switchRenderLayer('satellite');
        },
        switchRenderLayer(layer) {
            this.renderLayer = 'both'

            // Render only relevant layer after transition animation
            clearTimeout(this.renderTimeout);
            this.renderTimeout = setTimeout(() => {
                this.renderLayer = layer
            }, 2000);

            if (layer === 'satellite') {
                this.$refs.reticleCanvasLidar.classList.add("hidden");
            } else {
                this.$refs.reticleCanvasLidar.classList.remove("hidden");
            }
        },
        updateLoop(timestamp) {
            window.requestAnimationFrame(this.updateLoop);
            // WARNING: TODO:FIX: FRAMERATE-DEPENDENT
            const delta = (timestamp - this.lastTimestamp) / 100;

            let moved = false;

            // Track idle timer
            if (this.pos.x != this.lastpos.x || this.pos.y != this.lastpos.y) {
                this.lastMovement = timestamp;
                moved = true;

                if (this.idle) {
                    this.$emit('leave-idle');
                    // this.idle = false;
                }
            }
            this.lastpos.x = this.pos.x;
            this.lastpos.y = this.pos.y;

            if (timestamp - this.lastMovement > IDLE_TIME * 1000 && !this.idle) {
                if (this.distance(hotspots.find(spot => spot.id === this.currSpot), this.pos) > HOTSPOT_RADIUS) {
                    this.$emit('enter-idle');
                    this.onIdle();
                    // this.idle = true;
                }
            }

            this.processControllerInput(delta);
            // if (this.$refs.posreceivepending.value === 'true') {
            //     this.processIMInput(delta);
            // }

            // this.processIMInput(delta);
            if (this.$refs.reticle && moved) {
                this.redraw();
            }
            this.checkHotspots(delta);

            this.lastTimestamp = timestamp;
        },
        distance(a, b) {
            return Math.sqrt((a.x-b.x)**2 + (a.y-b.y)**2);
        }
    },
    mounted() {
        this.ctxSat = this.$refs.reticleCanvasSat.getContext("2d");
        this.ctxLidar = this.$refs.reticleCanvasLidar.getContext("2d");

        // Prepare images for both satellite and lidar
        this.imSat = new Image();
        this.imSat.src = this.$props.image;
        this.imLidar = new Image();
        this.imLidar.src = this.$props.lidarImage;

        if (this.$props.orientation === 'horizontal') {
            this.rX = 116;
            this.rY = 86;
        } else {
            this.rX = 86;
            this.rY = 116;
        }

        this.redraw();

        this.controller = navigator.getGamepads()[0];
        // document.addEventListener("mousemove", this.processMouseInput)
        

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
}

.reticle-a {
    width: 240px;
    height: 180px;
}

.reticle-b {
    width: 180px;
    height: 240px;
}

.reticle-c {
    width: 180px;
    height: 240px;
}

.databus {
    display: flex;
    flex-direction: row;

    width: 240px;
}

.databus input {
    width: 30%;
}

.r-idle {
    z-index: 8;
}

.reticle-canvas {
    display: block;
    opacity: 1;
    position: absolute;

    border-radius: inherit;
    padding: 4px;
    transition: opacity 1s;
}

.reticle-a .reticle-canvas {
    width: 232px;
    height: 172px;
    border-radius: 12px;
}

.reticle-b .reticle-canvas {
    width: 172px;
    height: 232px;
    border-radius: 86px;
}

.reticle-c .reticle-canvas {
    width: 172px;
    height: 232px;
    border-radius: 86px;
}

.visor {
    position: absolute;
    top: 0;   
}

.reticle-a .visor {
    width: 240px;
    height: 180px;
}

.reticle-b .visor {
    width: 180px;
    height: 240px;
}

.reticle-c .visor {
    width: 180px;
    height: 240px;
}

.anim-fade-out {
    animation: fade 2s forwards;
}

.anim-fade-in {
    animation: fade 2s reverse;
}

@keyframes fade {
    0% { opacity: 1!important; };
    100% {opacity: 0!important; };
}

.hidden {
    opacity: 0;
}

.anim-flash {
    animation: flash 0.15s linear 0s 1 alternate;
}

@keyframes flash {
    33% { transform: scale(1.1); }
    83% { transform: scale(0.95); }
}
</style>