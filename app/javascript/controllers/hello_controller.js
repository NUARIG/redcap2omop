import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    this.element.textContent = "Hello World, it's me!"

    let loadedAt = new Date().getTime();
    let counter = document.getElementById("counter");
    if (counter) {
      let updateFn = setInterval(function() {
        let elapsed = (new Date().getTime() - loadedAt)/1000;
        counter.innerHTML = elapsed;
      }, 800); // update 5x second for maximum fan usage
    }

  }
}
