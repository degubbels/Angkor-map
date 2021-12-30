<template>
    <div :class="idle ? 'reticle r-idle' : 'reticle'" ref="reticle">
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

const MOVEMENT_SPEED = 15;

const HOTSPOT_RADIUS = 4;

const MAGNET_RADIUS = 32;
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
        'deviceID',
        'orientation'
    ],
    emits: [
        'hotspotFound',
        'enter-idle',
        'leave-idle'
    ],
    data () {
        return {
            ctxSat: 0,      // Drawing context for satellite render layer
            ctxLidar: 0,    // Drawing context for lidar render layer
            pos: {  // Current position
                x: 0,
                y: 0,
            },      // Position last frome
            lastpos: {
                x: 0,
                y: 0,
            },
            rX: 116,        // Reticle radius on x-axis
            rY: 86,         // Reticle radius on x-axis
            lastTimestamp: 0,
            lastMovement: 0,
            currSpot: 'idle',
            imSat: null,
            imLidar: null,
            renderLayer: 'satellite',
            renderTimeout: null,
            currIX: 0,
            currIY: 0,
            newIMInput: false,
        };
    },
    methods: {
        // Redraw the reticle and visor
        redraw() {
            // Check bounds
            if (this.pos.x < 0) { this.pos.x = 0 }
            if (this.pos.x > 1920) { this.pos.x = 1920 }
            if (this.pos.y < 0) { this.pos.y = 0 }
            if (this.pos.y > 1200) { this.pos.y = 1200 }

            // Draw image section for full size map
            // Satellite
            if (this.renderLayer === 'satellite' || this.renderLayer === 'both') {
                this.ctxSat.drawImage(this.imSat, this.pos.x-this.rX, this.pos.y-this.rY,
                    2*this.rX, 2*this.rY,
                    0, 0,
                    2*this.rX, 2*this.rY);
            }

            // Lidar
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
        // Deprecated
        // processControllerInput(delta) {
            
        //     this.controller = navigator.getGamepads()[this.$props.gamepad];

        //     if (this.controller) {

        //         if (!isNaN(this.controller.axes[0]) && Math.abs(this.controller.axes[0]) > CONTROLLER_DEADZONE) {
        //             this.pos.x += this.controller.axes[0] * MOVEMENT_SPEED * delta;
        //         }

        //         if (!isNaN(this.controller.axes[1]) && Math.abs(this.controller.axes[1]) > CONTROLLER_DEADZONE) {
        //             this.pos.y += this.controller.axes[1] * MOVEMENT_SPEED * delta;
        //         }
        //     }
        // },
        // Deprecated
        // processMouseInput(e) {
        //     this.pos.x = e.x;
        //     this.pos.y = e.y;
        // },

        // Process input for input manager for new frame
        processMovement(delta) {

            // Check if new input has arrived
            // HID does not report input stop, move values have to be reset to 0
            if (!this.newIMInput) {
                this.currIX = 0;
                this.currIY = 0;
            } else {
                this.newIMInput = false;
            }

            // Calculate new position
            this.pos.x += this.currIX * MOVEMENT_SPEED * delta;
            this.pos.y += this.currIY * MOVEMENT_SPEED * delta;  
        },

        // Check the position of the reticle relative to the hotspots
        checkHotspots(delta) {
            
            // Check if the reticle is positioned on any of the hotspots
            for (const spot of hotspots) {
                const d = this.distance(this.pos, spot);
                if (d < MAGNET_RADIUS && d > 1) {
                    this.magnetAttract(spot, delta);
                }

                if (d < HOTSPOT_RADIUS) {
                    
                    // Prevent continuously reporting the same spot
                    if (this.hotspot !== spot.id && (this.pos.x != this.lastpos.x || this.pos.y != this.lastpos.y)) {
                        this.triggerHotspot(spot);
                    }
                }
            }
        },

        // Apply magnet attacting force to reticle from the given spot
        magnetAttract(spot, delta) {
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
        },

        // Handle hotspot activation for given spot
        triggerHotspot(spot) {
            this.$emit('hotspotFound', spot.id);
            this.currSpot = spot.id;
            Utils.triggerAnim(this.$refs.reticle, "flash", 1);

            this.switchRenderLayer(spot.type);
        },

        // Reset reticle to idle mode
        onIdle() {
            this.currSpot = 'idle';
            this.redraw();

            this.switchRenderLayer('satellite');
        },

        // Switch to rendering the diven layer ('satellite' | 'lidar')
        // Includes transition animation
        switchRenderLayer(layer) {

            // Render both layer during animation
            this.renderLayer = 'both'

            // Render only relevant layer after transition animation
            clearTimeout(this.renderTimeout);
            this.renderTimeout = setTimeout(() => {
                this.renderLayer = layer
            }, 2000);

            // Show or hide lidar layer
            if (layer === 'satellite') {
                this.$refs.reticleCanvasLidar.classList.add("hidden");
            } else {
                this.$refs.reticleCanvasLidar.classList.remove("hidden");
            }
        },

        // Handle incoming key presses
        onKey(e) {

            // Check valid key
            if (e.key) {
                
                // Check if the pressed key is a unicode-coded message from InputManager
                const code = e.key.charCodeAt(0).toString(16).toUpperCase();
                if (code.length === 4 && code[0] === 'A') {
                    this.processIMKeyInput(code);
                }
            }
        },

        // Process incoming InputManager unicode-coded input messages
        processIMKeyInput(code) {

            const deviceID = parseInt(code[1], 16);

            if (deviceID === this.$props.deviceID) {
                let x = parseInt(code[2], 16);
                let y = parseInt(code[3], 16);

                // Decode negative numbers (wrapped around single hex char)
                if (x >= 8) { x -= 15 }
                if (y >= 8) { y -= 15 }

                // Save input
                this.currIX = x;
                this.currIY = y;
                this.newIMInput = true;
            }
        },

        // Frame update loop
        updateLoop(timestamp) {

            // Keep loop running
            window.requestAnimationFrame(this.updateLoop);

            // Get frame delta
            const delta = (timestamp - this.lastTimestamp) / 100;

            // Track idle timer
            let moved = false;
            if (this.pos.x != this.lastpos.x || this.pos.y != this.lastpos.y) {
                this.lastMovement = timestamp;
                moved = true;

                if (this.idle) {
                    this.$emit('leave-idle');
                }
            }
            this.lastpos.x = this.pos.x;
            this.lastpos.y = this.pos.y;

            // Check to go in idle
            if (timestamp - this.lastMovement > IDLE_TIME * 1000 && !this.idle) {

                // Check not currently on hotspot
                if (this.distance(hotspots.find(spot => spot.id === this.currSpot), this.pos) > HOTSPOT_RADIUS) {
                    this.$emit('enter-idle');
                    this.onIdle();
                }
            }

            // Movement controll
            this.processMovement(delta);

            // Hotspot controll
            this.checkHotspots(delta);
            
            // Redraw only if necessary
            if (this.$refs.reticle && moved) {
                this.redraw();
            }

            this.lastTimestamp = timestamp;
        },
        distance(a, b) {
            return Math.sqrt((a.x-b.x)**2 + (a.y-b.y)**2);
        }
    },
    mounted() {

        // Create drawing context objects
        this.ctxSat = this.$refs.reticleCanvasSat.getContext("2d");
        this.ctxLidar = this.$refs.reticleCanvasLidar.getContext("2d");

        // Prepare images for both satellite and lidar
        this.imSat = new Image();
        this.imSat.src = this.$props.image;
        this.imLidar = new Image();
        this.imLidar.src = this.$props.lidarImage;

        // Set up radii
        if (this.$props.orientation === 'horizontal') {
            this.rX = 116;
            this.rY = 86;
        } else {
            this.rX = 86;
            this.rY = 116;
        }

        this.redraw();

        // Register listener to keyboard input (incl. InputManager messages)
        document.addEventListener('keydown', this.onKey);

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
    border-radius: 12px;
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