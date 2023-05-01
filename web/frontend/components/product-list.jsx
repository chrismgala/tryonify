import React, { useState, useCallback, useEffect } from 'react';
import { get } from 'lodash';
import {
  Card,
  EmptyState,
  Pagination,
  ResourceList,
  ResourceItem,
  TextStyle,
  Thumbnail
} from '@shopify/polaris';
import { useMutation, useQueryClient } from 'react-query';
import { useAppQuery, useAuthenticatedFetch } from '../hooks';
import createQueryString from '../lib/utils';
import ProductPicker from './product-picker';

async function fetchProducts({ queryKey }) {
  const [_key, {
    id,
    pagination
  }
  ] = queryKey
  const params = new URLSearchParams();

  Object.keys(pagination).forEach(key => {
    params.append(key, pagination[key]);
  });

  if (!id) return null;

  const { data } = await api.get();
  return data;
}

export default function ProductList({ id }) {
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const [pagination, setPagination] = useState({
    query: '',
    first: 20,
  });
  const [selectedItems, setSelectedItems] = useState([]);
  const [pickerOpen, setPickerOpen] = useState(false);

  const {
    isLoading,
    isRefetching,
    error,
    data
  } = useAppQuery({
    url: `/api/v1/selling_plan_groups/${encodeURIComponent(id)}/products?${createQueryString(pagination)}`
  });

  const saveMutation = useMutation(
    ({ addProducts, removeProducts }) => {
      return fetch(`/api/v1/selling_plan_groups/${encodeURIComponent(id)}/products`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ addProducts, removeProducts })
      }).then(async (response) => response.json());
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries(`/api/v1/selling_plan_groups/${encodeURIComponent(id)}/products?${createQueryString(pagination)}`)
        setSelectedItems([])
      }
    }
  )

  const handleNext = useCallback(() => {
    if (data?.pageInfo?.hasNextPage) setPagination(prevValue => ({
      after: data.pageInfo.endCursor,
      first: 20
    }));
  }, [data])

  const handlePrevious = useCallback(() => {
    if (data?.pageInfo?.hasPreviousPage) setPagination(prevValue => ({
      before: data.pageInfo.startCursor,
      last: 20
    }));
  }, [data])

  const openPicker = useCallback(() => {
    setPickerOpen(true);
  }, [])

  const closePicker = useCallback(() => {
    setPickerOpen(false);
  }, [])

  const handleSubmit = useCallback(async ({ addProducts, removeProducts }) => {
    if (
      (addProducts && addProducts.length > 0) ||
      (removeProducts && removeProducts.length > 0)
    ) {
      await saveMutation.mutate({ addProducts, removeProducts });
    }
  }, [])

  const handleRemove = useCallback(async () => {
    if (selectedItems && selectedItems.length > 0) {
      await saveMutation.mutate({ removeProducts: selectedItems })
    }
  }, [selectedItems]);

  const resourceName = {
    singular: 'product',
    plural: 'products'
  }

  const bulkActions = [
    {
      content: 'Remove Products',
      onAction: handleRemove
    }
  ]

  const emptyStateMarkup = (
    <EmptyState
      heading="No products are attached to this plan"
      action={{
        content: "Add Products",
        onAction: openPicker
      }}
    >
      <p>
        This plan will only be available for the attached products.
      </p>
    </EmptyState>
  )

  useEffect(() => {
    if (data?.pageInfo?.hasNextPage) {
      const url = `/api/v1/selling_plan_groups/${encodeURIComponent(id)}/products?${createQueryString({
        first: 20,
        after: data?.pageInfo?.endCursor,
      })}`
      queryClient.prefetchQuery(url, async () => await fetch(url))
    }
  }, [data, queryClient])

  const items = get(data, 'edges') ? get(data, 'edges') : [];

  return (
    <Card
      title="Products"
      actions={{
        content: 'Browse',
        onAction: openPicker
      }}
    >

      <ProductPicker
        id={id}
        onSubmit={handleSubmit}
        open={pickerOpen}
        onClose={closePicker}
      />
      <ResourceList
        resourceName={resourceName}
        emptyState={emptyStateMarkup}
        items={items}
        selectedItems={selectedItems}
        onSelectionChange={setSelectedItems}
        bulkActions={bulkActions}
        renderItem={renderItem}
        idForItem={({ node }) => node.id}
        resolveItemId={({ node }) => node.id}
        loading={isLoading || isRefetching}
        selectable
      />

      {(data?.pageInfo?.hasPreviousPage || data?.pageInfo?.hasNextPage) &&
        <Card.Section>
          <Pagination
            hasPrevious={data?.pageInfo?.hasPreviousPage}
            onPrevious={handlePrevious}
            hasNext={data?.pageInfo?.hasNextPage}
            onNext={handleNext}
          />
        </Card.Section>
      }
    </Card>
  )
}

function renderItem({ node }) {
  const { id, title, sku, images } = node;
  const image = images.edges.length > 0 ? images.edges[0].node : null;
  return (
    <ResourceItem
      id={id}
      media={image ? (
        <Thumbnail source={image.url} alt={image.altText} />
      ) : (
        null
      )}
      verticalAlignment="center"
    >
      <h3>
        <TextStyle variation='strong'>{title}</TextStyle>
      </h3>
      {sku && <span>{sku}</span>}
    </ResourceItem>
  )
}