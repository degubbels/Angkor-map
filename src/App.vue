<template>
<div>
    <img src="./res/background-labeled.png" class="background">
    <div class="tourcontainer" id="A">
        <Reticle 
            image="./src/res/hotspots-map.png"
            visor="./src/res/visor-A.png"
            @hotspot-found="onHotspotFound"
            :hotspot="aSpot"
        ></Reticle>
        <InfoBox :textSource="tourA" :hotspot="aSpot"></InfoBox>
    </div>
    <!-- <div class="tourcontainer" id="B">
        <InfoBox :textSource=tourA :hotspot="idle"></InfoBox>
    </div> -->
</div>
</template>
<script>
import { ref } from 'vue';
import Reticle from './components/Reticle.vue';
import InfoBox from './components/InfoBox.vue';
import tourA from './res/tourA.json';

// const aSpot = ref("idle");
export default {
    components: {
        Reticle,
        InfoBox
    },
    data() {
        return {
            aSpot: "idle",
            tourA: tourA,
        }
    },
    methods: {
        onHotspotFound(id) {
            this.aSpot = id;
            console.log(`hotspot: ${id}`);
        }
    }
}
</script>
<style>
@font-face {
    font-family: KhmerUI;
    /* src: url(./src/res/font/KhmerUI.ttf) format("truetype"),
         url(./src/res/font/KhmerUIb.ttf) format("truetype"); */
    src: url(./src/res/font/tt0010m_.ttf) format("truetype")
}

#app {
    font-family: KhmerUI, sans-serif;
    /* font-family: Avenir, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50; */
}

body {
    margin: 0;
}

.tourcontainer {
    position: absolute;
    top: 0;
    left: 0;
}
</style>
