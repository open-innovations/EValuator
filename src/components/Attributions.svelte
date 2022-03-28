<script>
  function attach(node) {
    const target = document.querySelector('#attribution');
    node.querySelectorAll('li').forEach(li => target.appendChild(li));
    node.remove();
  }
</script>

<div hidden use:attach>
  <li><a href="https://thenounproject.com/icon/energy-3321862/">Energy by Chintuza from NounProject.com</a></li>
  <!-- <li><a href="https://thenounproject.com/icon/pin-1069069/">Pin by Ralf Schmitzer from NounProject.com</a></li> -->
  <li><a href="https://thenounproject.com/icon/pin-1233347/">Pin by Drishya from NounProject.com</a></li>
  <li><a href="https://thenounproject.com/icon/co2-3844972/">Co2 by Soremba from NounProject.com</a></li>
  <li><a href="https://thenounproject.com/icon/warning-936898/">Warning by Thengakola from NounProject.com</a></li>
</div>