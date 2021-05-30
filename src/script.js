import './style.css'
import * as THREE from 'three'

import fragment from './fragment.glsl';
import vertex from './vertex.glsl';

var container;
var camera, scene, renderer;
var uniforms;

init();

function init() {
  container = document.getElementById('container');

  camera = new THREE.Camera();
  camera.position.z = 1;

  scene = new THREE.Scene();
  const loader = new THREE.TextureLoader();
  loader.load('./image.png', (texture) => {
    uniforms.u_texture.value = texture;
    uniforms.u_texture_uv.value = new THREE.Vector2(texture.image.width, texture.image.height);
    animate();
  })

  const geometry = new THREE.PlaneBufferGeometry(2, 2);

  uniforms = {
    u_time: {type: "f", value: 1.0},
    u_resolution: {type: "v2", value: new THREE.Vector2()},
    u_mouse: {type: "v2", value: new THREE.Vector3()},
    u_texture: {value: new THREE.Texture()},
    u_texture_uv: {value: new THREE.Vector2()}
  };

  var material = new THREE.ShaderMaterial({
    uniforms: uniforms,
    vertexShader: vertex,
    fragmentShader: fragment
  });

  var mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);

  renderer = new THREE.WebGLRenderer();
  renderer.setPixelRatio(window.devicePixelRatio);

  container.appendChild(renderer.domElement);

  onWindowResize();
  window.addEventListener('resize', onWindowResize, false);
  window.addEventListener('mousedown', () => {
    uniforms.u_mouse.value.z = 1;
  }, false);

  window.addEventListener('mouseup', () => {
    uniforms.u_mouse.value.z = 0;
  }, false);
  document.onmousemove = function (e) {
    uniforms.u_mouse.value.x = e.pageX
    uniforms.u_mouse.value.y = e.pageY
  }
}

function onWindowResize(event) {
  renderer.setSize(window.innerWidth, window.innerHeight);
  uniforms.u_resolution.value.x = renderer.domElement.width;
  uniforms.u_resolution.value.y = renderer.domElement.height;
}

function animate() {
  requestAnimationFrame(animate);
  render();
}

function render() {
  uniforms.u_time.value += 0.05;
  renderer.render(scene, camera);
}
