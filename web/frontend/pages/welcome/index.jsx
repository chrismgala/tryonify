import React, { useState, useCallback } from 'react';
import { Button, Card, Page, Layout, Link, Listbox, MediaCard, TextContainer } from '@shopify/polaris';
import { useNavigate } from '@shopify/app-bridge-react';
import { useAppQuery } from '../../hooks';
import {
  addAppBlock,
  removeAppBlock,
  reorderAppBlock
} from '../../assets';

const GettingStarted = () => (
  <Card title='Getting started' sectioned>
    <TextContainer>
      <p>This guide will provide you the key steps required to complete
        installation of TryOnify. If you have any questions about the content
        or require further assistance, please contact us by visiting our <Link url='https://www.tryonify.com' external>website</Link>.</p>
    </TextContainer>
  </Card>
)

const TrialPlan = () => (
  <Card title='Creating a trial plan' sectioned>
    <TextContainer>
      <p>Trial plans are attached to products that you specify and set the rules for the trial.
        Go to the
        {' '}
        <Link url="/plans/new">trial plan form</Link>
        {' '}
        to create a new plan.
        {' '}
        You must attach products to the plan after you save.</p>
    </TextContainer>
  </Card>
)

const ThemeCustomizations = ({ shopDomain }) => {
  const themeId = process.env.SHOPIFY_TRYONIFY_THEME_ID;
  return (
    <>
      <Card title='Customize your theme' sectioned>
        <TextContainer>
          <p>
            If your theme uses the Online Store 2.0 system, you can enable
            the app block and place the trial options on the product page.
          </p>
          <p>
            Legacy themes can enable the app embed block to automatically
            add the trial options to the product page.
          </p>
          <Button external url={`https://${shopDomain}/admin/themes/current/editor?context=apps&template=product&activateAppId=${themeId}/selling-plans-embed`}>
            Enable App Embed (Legacy Themes)
          </Button>
        </TextContainer>
      </Card>

      <MediaCard
        title='Add an app block'
        description='Using the theme customizer for your published theme, navigate to the template for product pages. Use the block list navigator to add a new block and add the Trial Offers block.'
      >
        <img
          alt=""
          width="100%"
          height="100%"
          style={{
            objectFit: 'cover',
            objectPosition: 'center',
          }}
          src={addAppBlock}
        />
      </MediaCard>

      <MediaCard
        title='Reorder an app block'
        description='Hover over the app block you want to move and grab the grid icon. You can then drag and drop to re-order the block.'
      >
        <img
          alt=""
          width="100%"
          height="100%"
          style={{
            objectFit: 'cover',
            objectPosition: 'center',
          }}
          src={reorderAppBlock}
        />
      </MediaCard>

      <MediaCard
        title='Remove an app block'
        description='Select an app block from the page to bring up the settings menu. At the bottom of the menu is a button to remove the block.'
      >
        <img
          alt=""
          width="100%"
          height="100%"
          style={{
            objectFit: 'cover',
            objectPosition: 'center',
          }}
          src={removeAppBlock}
        />
      </MediaCard>
    </>
  )
}

const ChargingOrders = () => (
  <Card title='Charging orders' sectioned>
    <TextContainer>
      <p>
        Trial orders that are ready to be charged will appear below on this page.
        Click on the order to navigate to the detail page where you will have the option
        to charge the remaining amount on the order.
      </p>
    </TextContainer>
  </Card>
)

const Returns = () => (
  <Card title='Returns' sectioned>
    <TextContainer>
      <p>
        Customers will be able to flag an item for return through the customer portal
        on your store. Orders with flagged items will be listed below, and details about which line item is being returned
        can be found in the
        {' '}
        <b>Notes</b>
        {' '}
        section on the order detail page. Once the line item has been restocked, the return
        will be marked as complete. You can also mark as complete in the list below which will mark all line items as returned.
      </p>
    </TextContainer>
  </Card>
)

export default function Welcome() {
  const {
    isLoading,
    data,
  } = useAppQuery({
    url: "/api/v1/shop"
  });
  const navigate = useNavigate();
  const [selected, setSelected] = useState('GettingStarted');

  const handleSelect = useCallback(setSelected, []);

  if (isLoading) return null;

  const panels = {
    GettingStarted,
    TrialPlan,
    ThemeCustomizations,
    ChargingOrders,
    Returns
  }

  return (
    <Page
      title='Welcome'
      primaryAction={{
        content: 'Go to app',
        onAction: () => navigate('/')
      }}
    >
      <Layout>
        <Layout.Section>
          {React.createElement(panels[selected], { shopDomain: data?.shop?.shopifyDomain })}
        </Layout.Section>
        <Layout.Section secondary>
          <Listbox accessibilityLabel='Welcome navigation' onSelect={handleSelect}>
            <Listbox.Option value='GettingStarted'>Getting started</Listbox.Option>
            <Listbox.Option value='TrialPlan'>Create a trial plan</Listbox.Option>
            <Listbox.Option value='ThemeCustomizations'>Customize your theme</Listbox.Option>
            <Listbox.Option value='ChargingOrders'>Charging Orders</Listbox.Option>
            <Listbox.Option value='Returns'>Returns</Listbox.Option>
          </Listbox>
        </Layout.Section>
        <Layout.Section />
      </Layout>
    </Page>
  )
}