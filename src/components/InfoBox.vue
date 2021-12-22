<template>
    <div class="infobox">
        <div class="textbox">
            <p class="text-en">{{textEn}}</p>
            <p class="text-es">{{textEs}}</p>
        </div>
        <img class="imagebox"
            :src="image"
            >
        <p class="namelabel">{{name}}</p>
    </div>
</template>z
<script>

const IMAGE_INTERVAL = 4;

export default {
    props: [
        'textSource',
        'hotspot'
    ],
    data () {
        return {
            image: null,
            textEn: "",
            textEs: "",
            name:"",
            imageIndex: 0,
            intervalLoop: null,
        }
    },
    mounted() {
        this.updateContents();
    },
    watch: {
        hotspot: function (val) {
            this.updateContents();
        }
    },
    methods: {
        updateContents() {
            this.name = this.$props.textSource[this.hotspot].name;
            this.textEn = this.$props.textSource[this.hotspot].en;
            this.textEs = this.$props.textSource[this.hotspot].es;

            const srcImg = this.$props.textSource[this.hotspot].img;
            window.clearInterval(this.intervalLoop);
            // Set image (slideshow)
            if (Array.isArray(srcImg)) {

                this.intervalLoop = window.setInterval(() => {
                    // Cycle images
                    this.imageIndex += 1;
                    this.imageIndex = this.imageIndex % srcImg.length;
                    this.image = srcImg[this.imageIndex];
                }, IMAGE_INTERVAL * 1000);

                this.imageIndex = 0;
                this.image = srcImg[this.imageIndex];
            } else {
                this.image = this.$props.textSource[this.hotspot].img;
            }
        }
    }
}
</script>
<style scoped>
.infobox {
    position: absolute;
    display: block;
}

.namelabel {
    position: absolute;
    z-index: 30;

    margin: 0px 4px;
    top: calc(152px - 26px);
    width: 282px;


    color: white;
    font-weight: 600;
    font-size: 26px;
}

.imagebox {
    display: block;
    position: absolute;
    z-index: 25;

    width: 282px;
    height: 152px;

    border: 2px solid;
}

.textbox {
    display: block;
    position: absolute;
    z-index: 20;
    top: 124px;
    left: 33px;

    width: 262px;
    /* height: 168px; */

    padding: 16px;
    padding-top: 24px;
    padding-bottom: 4px;

    background-color: rgba(0,0,0,0.5);

    font-size: 14.5px;
    font-weight: bold;
    text-align: left;
}

.text-en {
    color: white;
}

.text-es {
    color: #eff163;
}

#A > .infobox {
    top: 690px;
    left: 202px;

    color: #eff163;
}
#B > .infobox {
    top: 85px;
    left: 499px;

    color: #00ccff;
    transform: rotate(90deg);
}
</style>
