import React, { useCallback, useEffect, useState } from 'react';
import {
  Select,
  useData,
  useContainer,
  useSessionToken
} from '@shopify/admin-ui-extensions-react';

export default function Add() {
  const data = useData();
  const { close, done, setPrimaryAction, setSecondaryAction } = useContainer();
  const { getSessionToken } = useSessionToken();
  const [trialPlans, setTrialPlans] = useState([]);
  const [selected, setSelected] = useState(null);

  const fetchPlans = useCallback(async () => {
    const token = await getSessionToken();
    const resp = await fetch(`https://web-qla9.onrender.com/api/v1/selling_plan_groups`, {
      headers: {
        'authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      }
    });
    const { edges } = await resp.json();

    if (edges && edges.length > 0) {
      setTrialPlans(edges.map(({ node }) => node))
    }
  }, []);

  const handleSubmit = async () => {
    if (selected) {
      const token = await getSessionToken();

      await fetch(`https://web-qla9.onrender.com/api/v1/selling_plan_groups/${encodeURIComponent(selected)}/products`, {
        method: 'POST',
        headers: {
          'authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          addProducts: [data.productId],
          removeProducts: []
        })
      });

      done();
    }
  }

  useEffect(() => {
    fetchPlans();
  }, []);

  useEffect(() => {
    setPrimaryAction({
      content: 'Add to plan',
      onAction: handleSubmit,
    });

    setSecondaryAction({
      content: 'Cancel',
      onAction: () => close(),
    });
  }, [getSessionToken, close, done, setPrimaryAction, setSecondaryAction, selected]);

  useEffect(() => {
    setSelected(options[0].id);
  }, [options])

  const options = trialPlans.map(({ id, name }) => ({
    label: name,
    value: id,
  }));

  return (
    <>
      <Select
        label="Select a trial plan"
        options={options}
        onChange={setSelected}
        value={selected}
      />
    </>
  )
}