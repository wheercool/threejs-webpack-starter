import './style.css'
import * as THREE from 'three'
import * as dat from 'dat.gui'

import fragment from './fragment.glsl';
import vertex from './vertex.glsl';

// Debug
const gui = new dat.GUI()

// Canvas
const canvas = document.querySelector('canvas.webgl')

// Scene
const scene = new THREE.Scene()

// Objects
const geometry = new THREE.PlaneBufferGeometry(2, 2);

const uniforms = {
  u_time: {type: "f", value: 1.0},
  u_resolution: {type: "v2", value: new THREE.Vector2()},
  u_mouse: {type: "v2", value: new THREE.Vector2()}
};

// Materials

const material = new THREE.ShaderMaterial({
  uniforms: uniforms,
  vertexShader: vertex,
  fragmentShader: fragment
});

// Mesh
const plane = new THREE.Mesh(geometry, material)
scene.add(plane)

/**
 * Sizes
 */
const sizes = {
  width: window.innerWidth,
  height: window.innerHeight
}

window.addEventListener('resize', () => {
  // Update sizes
  sizes.width = window.innerWidth
  sizes.height = window.innerHeight

  // Update camera
  camera.aspect = sizes.width / sizes.height
  camera.updateProjectionMatrix()

  // Update renderer
  renderer.setSize(sizes.width, sizes.height)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))

  uniforms.u_resolution.value.x = renderer.domElement.width;
  uniforms.u_resolution.value.y = renderer.domElement.height;
})

document.onmousemove = function (e) {
  uniforms.u_mouse.value.x = e.pageX
  uniforms.u_mouse.value.y = e.pageY
}

/**
 * Camera
 */
// Base camera
const camera = new THREE.Camera()
camera.position.z = 1;

scene.add(camera)

/**
 * Renderer
 */
const renderer = new THREE.WebGLRenderer({
  canvas: canvas
})
renderer.setSize(sizes.width, sizes.height)
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))

/**
 * Animate
 */

const tick = () => {
  uniforms.u_time.value += 0.05;
  // Render
  renderer.render(scene, camera);
  // Call tick again on the next frame
  window.requestAnimationFrame(tick)
}

tick()
