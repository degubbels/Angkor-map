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
            :src=visor>
    </div>
</template>
<script>

let r = 100;

const CONTROLLER_DEADZONE = 0.15;
const MOVEMENT_SPEED = 10;

const HOTSPOT_RADIUS = 10;

const hotspots = [
    { id: 'A1', x: 896, y: 738 },
    { id: 'idle', x: 0, y: 0 }
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
            posX: 0,
            posY: 0,
            rX: 100,
            rY: 70,
        };
    },
    methods: {
        redraw() {
            // Draw image section for full size map
            this.ctx.drawImage(this.im, this.posX-this.rX+4, this.posY-this.rY+4,
                2*this.rX, 2*this.rY,
                0, 0,
                2*this.rX, 2*this.rY);

            // Move to position
            this.$refs.reticle.style.left = this.posX - this.rX + "px"
            this.$refs.reticle.style.top = this.posY - this.rY + "px"
        },
        processControllerInput() {
            
            // TODO: replace polling with listeners
            if (!this.controller) {
                this.controller = navigator.getGamepads()[0];

            } else {

                // WARNING: this code does not work on chromium (input polling required), only firefox is tested
                if (!isNaN(this.controller.axes[0]) && Math.abs(this.controller.axes[0]) > CONTROLLER_DEADZONE) {
                    this.posX += this.controller.axes[0] * MOVEMENT_SPEED;
                }

                if (!isNaN(this.controller.axes[1]) && Math.abs(this.controller.axes[1]) > CONTROLLER_DEADZONE) {
                    this.posY += this.controller.axes[1] * MOVEMENT_SPEED;
                }
            }
        },
        processMouseInput(e) {
            this.posX = e.x;
            this.posY = e.y;
        },
        checkHotspots() {

            for (const spot of hotspots) {
                if (Math.abs(spot.x - this.posX) < HOTSPOT_RADIUS
                    && Math.abs(spot.y - this.posY) < HOTSPOT_RADIUS) {
                    
                    if (this.hotspot !== spot.id) {
                        this.$emit('hotspotFound', spot.id);
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
    height: 100%
}
</style>