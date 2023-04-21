import React, { useState, useCallback } from 'react';
import {
  Page,
  Layout,
  Card,
  Banner,
  ResourceList,
  ResourceItem,
  EmptyState,
  Stack,
  TextStyle,
  TextField,
} from '@shopify/polaris';
import { get } from 'lodash';
import { DateTime } from 'luxon';
import { useMutation, useQueryClient } from 'react-query';
import createQueryString from '../../lib/utils';
import { useAppQuery, useAuthenticatedFetch } from '../../hooks';
import DraftOrderPicker from '../../components/draft-order-picker';

export default function Checkouts() {
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const [pagination, setPagination] = useState({
    page: 1,
    query: '',
  });
  const [pickerOpen, setPickerOpen] = useState(false);
  const [selectedItems, setSelectedItems] = useState([]);
  const { isLoading, error, data } = useAppQuery({
    url: `/api/v1/checkouts?${createQueryString(pagination)}`,
    debounceWait: 300
  });

  const createMutation = useMutation(
    (draftOrderId) => fetch(`/api/v1/checkouts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ id: draftOrderId }),
    }),
    {
      onSuccess: () => {
        queryClient.invalidateQueries([`/api/v1/checkouts?${createQueryString(pagination)}`]);
      },
    }
  );

  const destroyMutation = useMutation(
    (ids) => fetch(`/api/v1/checkouts/bulk_destroy`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ ids: ids }),
    }),
    {
      onSuccess: () => {
        queryClient.invalidateQueries([`/api/v1/checkouts?${createQueryString(pagination)}`]);
      },
    }
  );

  const openPicker = useCallback(() => {
    setPickerOpen(true);
  }, []);

  const closePicker = useCallback(() => {
    setPickerOpen(false);
  }, []);

  const primaryAction = {
    content: 'New Checkout',
    onAction: openPicker,
  }

  const promotedBulkActions = [
    {
      content: 'Delete checkouts',
      onAction: () => destroyMutation.mutate(selectedItems),
    }
  ]

  const createCheckoutLink = useCallback((draftOrderId) => {
    createMutation.mutate(draftOrderId);
    closePicker();
  }, []);

  const emptyState = !isLoading && (
    <Card sectioned>
      <EmptyState
        heading="Manage your checkouts"
        action={primaryAction}
      >
        <p>Create checkout links from draft orders with line items converted to trial offers.</p>
      </EmptyState>
    </Card>
  );

  return (
    <Page title="Checkouts" primaryAction={(!isLoading && data?.results?.length > 0) ? primaryAction : null}>
      {createMutation.isError
        && (
          <Stack vertical>
            <Banner title="Error" status="critical">
              {get(createMutation, 'error.response.data.message') ?? createMutation.error.message}
            </Banner>
          </Stack>
        )}

      <Layout>
        <Layout.Section>
          <Card>
            <ResourceList
              resourceName={{ singular: 'checkout', plural: 'checkouts' }}
              items={data?.results ?? []}
              loading={isLoading}
              selectedItems={selectedItems}
              onSelectionChange={setSelectedItems}
              promotedBulkActions={promotedBulkActions}
              renderItem={item => {
                const { id, name, createdAt, link } = item;
                const dt = DateTime.fromISO(createdAt);
                const date = dt.toLocaleString(DateTime.DATE_SHORT);

                return (
                  <ResourceItem id={id}>
                    <Stack>
                      <Stack.Item fill>
                        <h3>
                          <TextStyle variation="strong">
                            {name}
                          </TextStyle>
                        </h3>
                        <div>{date}</div>
                      </Stack.Item>
                      <Stack.Item>
                        <TextField label="Checkout link" readOnly value={link} />
                      </Stack.Item>
                    </Stack>
                  </ResourceItem>
                );
              }}
              emptyState={emptyState}
              selectable
            />
          </Card>
        </Layout.Section>
      </Layout>
      <DraftOrderPicker open={pickerOpen} onClick={createCheckoutLink} onClose={closePicker} />
    </Page>
  );
}