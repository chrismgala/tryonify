import React from 'react';
import {
  useExtensionApi,
  render,
  Banner,
  useSettings,
} from '@shopify/checkout-ui-extensions-react';

render('Checkout::Dynamic::Render', () => <App />);

function App() {
  const { extensionPoint } = useExtensionApi();
  const { title, text, status } = useSettings();
  return (
    <Banner title={title} status={status}>
      {text}
    </Banner>
  );
}