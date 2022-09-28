import React from 'react';
import { render, extend, Text, useExtensionApi } from '@shopify/admin-ui-extensions-react';
import Add from './Add.jsx';
import Create from './Create.jsx'
import Edit from './Edit.jsx'
import Remove from './Remove.jsx'

// Your extension must render all four modes
extend(
  'Admin::Product::SubscriptionPlan::Add',
  render(() => <Add />),
)
extend(
  'Admin::Product::SubscriptionPlan::Create',
  render(() => <Create />),
)
extend(
  'Admin::Product::SubscriptionPlan::Remove',
  render(() => <Remove />),
)
extend(
  'Admin::Product::SubscriptionPlan::Edit',
  render(() => <Edit />),
)

function App() {
  const { extensionPoint } = useExtensionApi()
  return <Text>Welcome to the {extensionPoint} extension!</Text>
}
