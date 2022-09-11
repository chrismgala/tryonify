import React from 'react';
import {
  Card,
  EmptyState,
  ResourceList,
  ResourceItem,
  TextStyle,
} from '@shopify/polaris';

export default function SellingPlanList({ items, onAction }) {
  const resourceName = {
    singular: 'plan',
    plural: 'plans',
  };

  if (items && items.length > 0) {
    return (
      <ResourceList
        resourceName={resourceName}
        items={items}
        renderItem={({ node }) => {
          const { id, name } = node;
          return (
            <ResourceItem
              id={id}
              verticalAlignment="center"
              url={`/plans/${encodeURIComponent(id)}`}
            >
              <h3>
                <TextStyle variation="strong">{name}</TextStyle>
              </h3>
            </ResourceItem>
          );
        }}
      />
    );
  }

  return (
    <Card sectioned>
      <EmptyState
        heading="Manage your plans"
        action={{ content: 'Create plan', onAction }}
      >
        <p>Create plans to offer new purchase options to your users.</p>
      </EmptyState>
    </Card>
  );
}
