handlePayLater() {
  // ... existing code ...
  
  // Update the redirect to go to billing page
  window.location.href = '/billing';
  
  // Close the modal if needed
  this.closeModal();
} 