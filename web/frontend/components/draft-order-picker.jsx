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

export default function DraftOrderPicker({ onClick, open, onClose }) {
  const fetch = useAuthenticatedFetch();
  const queryClient = useQueryClient();
  const [pagination, setPagination] = useState({
    query: '',
    first: 20,
  });
  const handleQueryValueChange = useCallback(
    (value) => setPagination(prevValue => ({
      ...prevValue,
      query: value,
    })),
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
    url: `/api/v1/draft_orders?${createQueryString(pagination)}`,
    reactQueryOptions: {
      keepPreviousData: true,
    }
  });

  const handleNext = useCallback(() => {
    if (data?.pageInfo?.hasNextPage) setPagination(prevValue => ({
      query: prevValue.query,
      after: data.pageInfo.endCursor,
    }));
  }, [data])

  const handlePrevious = useCallback(() => {
    if (data?.pageInfo?.hasPreviousPage) setPagination(prevValue => ({
      query: prevValue.query,
      before: data.pageInfo.startCursor,
    }));
  }, [data])

  const handleSubmit = useCallback(() => {
    onClose()
  }, [])

  // Reset data on close
  useEffect(() => {
    if (!open) {
      setPagination({
        query: '',
        first: 20
      });
    }
  }, [open])

  // Paginate
  useEffect(() => {
    if (data?.pageInfo?.hasNextPage) {
      const url = `/api/v1/draft_orders?${createQueryString({
        first: 20,
        after: data?.pageInfo?.endCursor,
      })}`
      queryClient.prefetchQuery(url, async () => await fetch(url))
    }
  }, [data, queryClient]);

  const resourceName = {
    singular: 'draft order',
    plural: 'draft orders'
  }

  const filterControl = (
    <Filters
      queryValue={pagination?.query}
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

  return (
    <Modal
      large
      title="Choose a draft order"
      open={open}
      onClose={onClose}
      footer={footer}
    >
      <ResourceList
        resourceName={resourceName}
        items={data?.edges ?? []}
        renderItem={({ node }) => {
          const { id, name } = node;
          return (
            <ResourceItem
              id={id}
              verticalAlignment="center"
              onClick={onClick}
            >
              <h3>
                <TextStyle variation='strong'>{name}</TextStyle>
              </h3>
            </ResourceItem>
          )
        }}
        filterControl={filterControl}
        loading={isLoading}
        selectable={false}
      />
    </Modal>
  )
}

function renderItem(item) {

}