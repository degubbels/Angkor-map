<template>
    <canvas
        id="l1"
        class="reticle"
        ref="reticle"
        width="200"
        height="140"
        >
    </canvas>
</template>
<script>

let r = 100;

const CONTROLLER_DEADZONE = 0.15;
const MOVEMENT_SPEED = 10;

export default {
    props: [
        'image'
    ],
    data () {
        return {
            ctx: 0,
            im: null,
            controller: null,
            posX: 0,
            posY: 0,
        };
    },
    methods: {
        redraw() {
            // Draw image section for full size mapj
            this.ctx.drawImage(this.im, this.posX-r, this.posY-r, 2*r, 2*r, 0, 0, 2*r, 2*r);

            // Move to position
            this.$refs.reticle.style.top = this.posY - r + "px"
            this.$refs.reticle.style.left = this.posX - r + "px"
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
        updateLoop() {
            window.requestAnimationFrame(loop)
            // WARNING: TODO:FIX: FRAMERATE-DEPENDENT

            this.processControllerInput();
            this.redraw();
        },
    },
    mounted() {
        this.ctx = this.$refs.reticle.getContext("2d")
        this.im = new Image();
        this.im.src = this.$props.image;

        this.controller = navigator.getGamepads()[0];
        // document.addEventListener("mousemove", this.redraw)

        // Start interaction loop
        window.loop = this.updateLoop;
        loop();
    },

}
</script>
<style scoped>
.reticle {
    position: absolute;
    display: block;

    border:1px black solid;
    box-shadow: 5px 5px 10px #1e1e1e;
    border-radius: 20px;
}
</style>