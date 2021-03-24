let loadedAt = new Date().getTime();
let updateFn = setInterval(function() {
  let elapsed = (new Date().getTime() - loadedAt)/1000;
  document.getElementById("counter").innerHTML = elapsed;
}, 200); // update 5x second for maximum fan usage
