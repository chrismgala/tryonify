import React from 'react';
import styles from './empty.module.css';

export default function Empty({ children }) {
  return (
    <div className={styles.empty}>
      {children}
    </div>
  )
}