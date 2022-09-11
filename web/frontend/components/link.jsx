import React from 'react';
import { Link } from 'react-router-dom';

function LinkComponent({ url, external, ...rest }) {
  if (external) {
    return (
      <a target="_blank" href={url} {...rest} />
    );
  }

  return (
    <Link to={url} {...rest} />
  );
}

export default LinkComponent;
