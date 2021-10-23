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
            name:"",
            hotspot: "idle",
        }
    },
    mounted() {
        this.name = this.$props.textSource[this.hotspot].name;
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
}
</style>
