import React, { useState, useCallback } from 'react';
import {
  Card,
  Page,
  Layout,
  Tabs,
  TextField
} from '@shopify/polaris';
import { debounce } from 'lodash'
import OrderList from '../components/order-list';

export default function Home() {
  const [selected, setSelected] = useState(0);
  const [query, setQuery] = useState('')

  const handleQueryChange = useCallback(value => setQuery(value), []);
  const handleTabChange = useCallback((selectedTabIndex) => setSelected(selectedTabIndex), []);

  const tabs = [
    {
      id: 'all',
      content: 'All',
      accessibilityLabel: 'All orders',
      panelID: 'all-content',
    },
    {
      id: 'overdue',
      content: 'Payment Due',
      accessibilityLabel: 'Payment due',
      panelID: 'overdue-content'
    },
    {
      id: 'pending',
      content: 'Pending',
      accessibilityLabel: 'Pending',
      panelID: 'pending-content'
    },
    {
      id: 'returns',
      content: 'Returns',
      accessibilityLabel: 'Returns',
      panelID: 'returns-content'
    },
    {
      id: 'failed_payments',
      content: 'Failed Payments',
      accessibilityLabel: 'Failed payments',
      panelID: 'failed-payments-content'
    }
  ]

  return (
    <Page title="Orders">
      <Layout>
        <Layout.Section>
          <Card>
            <Card.Section>
              <TextField name="query" placeholder="Search..." value={query} onChange={handleQueryChange} />
            </Card.Section>
            <Tabs tabs={tabs} selected={selected} onSelect={handleTabChange}>
              <OrderList query={query} status={tabs[selected].id} />
            </Tabs>
          </Card>
        </Layout.Section>
        <Layout.Section />
      </Layout>
    </Page>
  );
}
