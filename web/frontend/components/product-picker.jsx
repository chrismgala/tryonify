import React, { useState, useCallback, useEffect, useRef } from 'react';
import { get, difference, debounce } from 'lodash';
import {
  Button,
  Filters,
  Modal,
  Pagination,
  ResourceList,
  ResourceItem,
  TextStyle,
  Thumbnail
} from '@shopify/polaris';
import { useQueryClient } from 'react-query';
import { useAppQuery, useAuthenticatedFetch } from '../hooks';
import createQueryString from '../lib/utils';

export default function ProductPicker({ id, onSubmit, open, onClose }) {
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const [pagination, setPagination] = useState({
    query: '',
    first: 20,
  });
  const [queryValue, setQueryValue] = useState('');
  const [selectedItems, setSelectedItems] = useState([]);
  const addedProducts = useRef([]);
  const removedProducts = useRef([]);
  const updateQuery = useRef(debounce((value) => setPagination(prevValue => ({
    ...prevValue,
    query: value
  })), 500));
  const handleQueryValueChange = useCallback(
    (value) => setQueryValue(value),
    []
  );
  const handleQueryValueRemove = useCallback(() => setQueryValue(''), []);
  const handleClearAll = useCallback(() => {
    handleQueryValueRemove();
  }, [handleQueryValueRemove]);

  const {
    isLoading,
    error,
    data,
  } = useAppQuery({
    url: `/api/v1/products?${createQueryString(pagination)}`,
    reactQueryOptions: {
      keepPreviousData: true,
    }
  });

  const handleNext = useCallback(() => {
    if (data?.pageInfo?.hasNextPage) setPagination(prevValue => ({
      query: prevValue.query,
      after: data.pageInfo.endCursor,
      first: 20
    }));
  }, [data])

  const handlePrevious = useCallback(() => {
    if (data?.pageInfo?.hasPreviousPage) setPagination(prevValue => ({
      query: prevValue.query,
      before: data.pageInfo.startCursor,
      last: 20
    }));
  }, [data])

  // Track products added or removed from selling plan
  const handleSelection = useCallback((selection) => {
    const checked = difference(selection, selectedItems);
    const unchecked = difference(selectedItems, selection);
    addedProducts.current = [];
    removedProducts.current = [];

    // Process newly checked products
    checked.forEach(selected => {
      const { node: foundProduct } = data.edges.find(product => product.node.id === selected);

      if (!foundProduct?.sellingPlanGroups?.edges.find(({ node }) => node.id === id)) {
        addedProducts.current = [...addedProducts.current, selected];
      } else {
        const index = removedProducts.current.indexOf(selected);
        removedProducts.current.splice(index, 1);
      }
    });

    // Process newly unchecked products
    unchecked.forEach(selected => {
      const { node: foundProduct } = data.edges.find(product => product.node.id === selected);

      if (foundProduct?.sellingPlanGroups?.edges.find(({ node }) => node.id === id)) {
        removedProducts.current = [...removedProducts.current, selected];
      } else {
        const index = addedProducts.current.indexOf(selected);
        addedProducts.current.splice(index, 1);
      }
    });
    setSelectedItems(selection);
  }, [selectedItems])

  const handleSubmit = useCallback(() => {
    // Submit products to be added to plan
    onSubmit({ addProducts: addedProducts.current, removeProducts: removedProducts.current })

    // Reset modal state
    addedProducts.current = [];
    removedProducts.current = [];

    onClose()
  }, [addedProducts, removedProducts])

  const resourceName = {
    singular: 'product',
    plural: 'products'
  }

  const filterControl = (
    <Filters
      queryValue={queryValue}
      filters={[]}
      onQueryChange={handleQueryValueChange}
      onQueryClear={handleQueryValueRemove}
      onClearAll={handleClearAll}
    >
      <div style={{ paddingLeft: "8px" }}>
        <Button onClick={() => { }}>Search</Button>
      </div>
    </Filters>
  )

  const footer = (
    <Pagination
      hasPrevious={data?.pageInfo?.hasPreviousPage}
      onPrevious={handlePrevious}
      hasNext={data?.pageInfo?.hasNextPage}
      onNext={handleNext}
    />
  )

  useEffect(() => {
    if (data?.pageInfo?.hasNextPage) {
      const url = `/api/v1/products?${createQueryString({
        first: 20,
        after: data?.pageInfo?.endCursor,
      })}`
      queryClient.prefetchQuery(url, async () => await fetch(url))
    }
  }, [data, queryClient])

  useEffect(() => {
    updateQuery.current(queryValue);
  }, [queryValue])

  useEffect(() => {
    const products = get(data, 'edges')
    if (products) {
      const selected = products.reduce((acc, value) => {
        const newAcc = acc;
        const sellingPlanGroups = get(value, 'node.sellingPlanGroups.edges');

        if (!sellingPlanGroups) return newAcc;

        const hasPlan = sellingPlanGroups.find(plan => plan.node.id === id);

        if (hasPlan) {
          newAcc.push(value.node.id);
        }

        return newAcc;
      }, []);
      setSelectedItems(selected);
    }
  }, [data, pagination]);

  return (
    <Modal
      large
      title="Product Picker"
      open={open}
      onClose={onClose}
      primaryAction={{
        content: 'Done',
        onAction: handleSubmit,
      }}
      secondaryActions={{
        content: 'Cancel',
        onAction: onClose,
      }}
      footer={footer}
    >
      <ResourceList
        resourceName={resourceName}
        items={get(data, 'edges') || []}
        selectedItems={selectedItems}
        onSelectionChange={handleSelection}
        renderItem={renderItem}
        filterControl={filterControl}
        loading={isLoading}
        idForItem={({ node }) => node.id}
        resolveItemId={({ node }) => node.id}
        selectable
      />
    </Modal>
  )
}

function renderItem({ node }) {
  const { id, title, images } = node;
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
    </ResourceItem>
  )
}