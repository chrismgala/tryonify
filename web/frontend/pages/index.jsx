import React from 'react';
import { Page, Layout } from '@shopify/polaris';
import Onboarding from '../components/onboarding';
import OrderList from '../components/order-list';
import ReturnList from '../components/return-list';

export default function Home() {
  return (
    <Page title="Overview">
      <Layout>
        <Layout.Section>
          <Onboarding />
          <OrderList title="Ready to charge" query="overdue" />
          <OrderList title="Pending trials" query="pending" />
          <ReturnList title="Pending returns" />
        </Layout.Section>
      </Layout>
    </Page>
  );
}
