<template>
<div>
    <img src="./res/background.png" class="background">
    <div class="tourcontainer" id="A">
        <Reticle image="./src/res/image001.jpg"></Reticle>
        <InfoBox :textSource=tourA></InfoBox>
    </div>
</div>
</template>
<script setup>
import Reticle from './components/Reticle.vue';
import InfoBox from './components/InfoBox.vue';
import tourA from './res/tourA.json';

</script>
<style>
#app {
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
