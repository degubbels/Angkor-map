<template>
    <div class="infobox">
        <div class="textbox">
            <p class="text-en">{{textEn}}</p>
            <p class="text-es">{{textEs}}</p>
        </div>
        <img class="imagebox"
            :src="image"
            >
    </div>
</template>

<script>

export default {
    props: [
        'textSource'
    ],
    data () {
        return {
            image: null,
            textEn: "",
            textEs: "",
            hotspot: "idle",
        }
    },
    mounted() {
        this.textEn = this.$props.textSource[this.hotspot].en;
        this.textEs = this.$props.textSource[this.hotspot].es;
        this.image = this.$props.textSource[this.hotspot].img;
    },
}
</script>
<style scoped>
.infobox {
    position: absolute;
    display: block;
}

.imagebox {
    display: block;
    position: absolute;
    z-index: 20;

    width: 282px;
    height: 152px;

    border: 2px solid #eff163;
}

.textbox {
    display: block;
    position: absolute;
    z-index: 10;
    top: 124px;
    left: 33px;

    width: 262px;
    height: 168px;

    padding: 16px;
    padding-top: 24px;

    background-color: rgba(0,0,0,0.5);

    font-size: 11pt;
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
}
</style>
