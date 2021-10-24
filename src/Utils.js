export default class Utils {

    static triggerAnim(el, anim, duration) {
        // Trigger animation with given name, automatically remove class after use

        el.classList.add(`anim-${anim}`);
        
        setTimeout(() => {
            el.classList.remove(`anim-${anim}`);
        }, duration * 1000);
    }
}