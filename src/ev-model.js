import App from './ev-model-app.svelte';

export const init = (target) => {
  const app = new App({
    target: target,
    props: {
      name: 'world'
    }
  });  
}
