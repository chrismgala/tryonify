import React, { useEffect } from 'react';
import {
  Text,
  useData,
  useContainer,
  useSessionToken
} from '@shopify/admin-ui-extensions-react';

export default function Remove() {
  const data = useData();
  const { close, done, setPrimaryAction, setSecondaryAction } = useContainer();
  const { getSessionToken } = useSessionToken();

  const handleSubmit = async () => {
    const token = await getSessionToken();

    await fetch(`https://tryonify.ngrok.io/api/v1/selling_plan_groups/${encodeURIComponent(data.sellingPlanGroupId)}/products`, {
      method: 'POST',
      headers: {
        'authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        addProducts: [],
        removeProducts: [data.productId]
      })
    });

    done();
  }

  useEffect(() => {
    setPrimaryAction({
      content: 'Remove from plan',
      onAction: handleSubmit,
    });

    setSecondaryAction({
      content: 'Cancel',
      onAction: () => close(),
    });
  }, [getSessionToken, close, done, setPrimaryAction, setSecondaryAction]);

  return (
    <Text>Remove this product from the selling plan group?</Text>
  )
}