<template>
<div>
    <img src="/background-new.png" class="background">
    <div class="tourcontainer" id="A">
        <InfoBox :textSource="tour" :hotspot="aSpot"></InfoBox>
        <Reticle 
            image="/hotspots-map-new.png"
            lidarImage="/hotspots-map-overlay-lidar-adjusted.png"
            visor="/visor-A.png"
            :deviceID=1
            @hotspot-found="onAHotspotFound"
            :hotspot="aSpot"
            :idle="this.aIdle"
            @enter-idle="this.aIdle = true; this.aSpot = 'idle'"
            @leave-idle="this.aIdle = false"
            class="reticle-a"
            startPosX=692
            startPosY=790
            orientation='horizontal'
        ></Reticle>
    </div>
    <div class="tourcontainer" id="B">
        <InfoBox :textSource="tour" :hotspot="bSpot"></InfoBox>
        <Reticle 
            image="/hotspots-map-new.png"
            lidarImage="/hotspots-map-overlay-lidar-adjusted.png"
            visor="/visor-B.png"
            :deviceID=2
            @hotspot-found="onBHotspotFound"
            :hotspot="bSpot"
            :idle="this.bIdle"
            @enter-idle="this.bIdle = true; this.bSpot = 'idle'"
            @leave-idle="this.bIdle = false"
            class='reticle-b'
            startPosX=640
            startPosY=226
            orientation='vertical'
        ></Reticle>
    </div>
    <div class="tourcontainer" id="C">
        <InfoBox :textSource="tour" :hotspot="cSpot"></InfoBox>
        <Reticle 
            image="/hotspots-map-new.png"
            lidarImage="/hotspots-map-overlay-lidar-adjusted.png"
            visor="/visor-C.png"
            :deviceID=3
            @hotspot-found="onCHotspotFound"
            :hotspot="cSpot"
            :idle="this.cIdle"
            @enter-idle="this.cIdle = true; this.cSpot = 'idle'"
            @leave-idle="this.cIdle = false"
            class='reticle-c'
            startPosX=1514
            startPosY=519
            orientation='vertical'
        ></Reticle>
    </div>
</div>
</template>
<script>
import { ref } from 'vue';
import Reticle from './components/Reticle.vue';
import InfoBox from './components/InfoBox.vue';
import tour from './res/tour.json';

// const aSpot = ref("idle");
export default {
    components: {
        Reticle,
        InfoBox
    },
    data() {
        return {
            aSpot: "idle",
            aIdle: true,
            bSpot: "idle",
            bIdle: true,
            cSpot: "idle",
            cIdle: true,
            tour: tour,
            idleTimer: 0
        }
    },
    methods: {
        onAHotspotFound(id) {
            this.aSpot = id;
        },
        onBHotspotFound(id) {
            this.bSpot = id;
        },
        onCHotspotFound(id) {
            this.cSpot = id;
        },
    }
}
</script>
<style>
/* Hide Mouse cursor */
* {
    cursor: none;
}

body {
    margin: 0;
    overflow: hidden
}

body::-webkit-scrollbar {
    display: none;
}

@font-face {
    font-family: KhmerUI;
    /* src: url(./src/res/font/KhmerUIb.ttf) format("truetype") */
         /*url(./src/res/font/KhmerUIb.ttf) format("truetype"); */
    src: url(/font/tt0010m_.ttf) format("truetype")
}

#app {
    font-family: KhmerUI, sans-serif;
    /* font-family: Avenir, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50; */
}

.tourcontainer {
    position: absolute;
    top: 0;
    left: 0;
}
</style>
